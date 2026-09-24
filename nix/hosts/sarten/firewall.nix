{ ... }:
{
    flake.modules.nixos.sarten-firewall = { config, lib, pkgs, ... }:
    let
        lan     = "eno1";
        lanAddr = (lib.head config.networking.interfaces.${lan}.ipv4.addresses).address;
        lanNet  = "192.168.1.0/24";
        tailnet = "100.64.0.0/10";
        bridges = [ "incusbr0" "labbr0" ];
        agent   = "1514, 1515";
    in {
        # The NixOS input chain drops by default, and Incus's own accepts cannot
        # override a drop, so instances get no DHCP or DNS without these.
        networking.firewall.interfaces = lib.genAttrs bridges (_: {
            allowedUDPPorts = [ 53 67 ];
            allowedTCPPorts = [ 53 ];
        });

        # Drop-only table hooked just ahead of nixos-fw, Docker and Incus. A drop
        # in any base chain is final; an accept here only means "not dropped
        # here", so every other table still gets its say.
        networking.nftables.tables.sarten-guard = {
            family  = "inet";
            content = ''
                chain input {
                    type filter hook input priority filter - 10; policy accept;

                    ct state established,related accept
                    iifname { "incusbr0", "labbr0" } udp dport { 53, 67 } accept
                    iifname { "incusbr0", "labbr0" } tcp dport 53 accept
                    iifname { "incusbr0", "labbr0" } drop
                }

                chain forward {
                    type filter hook forward priority filter - 10; policy accept;

                    ct state established,related accept

                    # Docker DNATs its published ports, so they are forwarded,
                    # not input, and nixos-fw never sees them.
                    iifname "${lan}" ct status dnat drop

                    # br_netfilter sends bridged frames through this hook too.
                    iifname "incusbr0" oifname "incusbr0" accept
                    iifname "labbr0" oifname "labbr0" accept

                    iifname { "incusbr0", "labbr0" } oifname "br-*" tcp dport { ${agent} } accept
                    iifname { "incusbr0", "labbr0" } oifname { "br-*", "docker0" } drop

                    iifname "labbr0" drop

                    iifname "incusbr0" oifname { "labbr0", "tailscale0" } drop
                    iifname "incusbr0" ip daddr { ${lanNet}, ${tailnet} } drop
                }
            '';
        };

        # The network table in docs/LAYOUT.md, as a test. Launches throwaway
        # containers on both bridges, probes from inside them, and deletes them.
        # Every "closed" probe is repeated from the host, where the guard does
        # not apply: if the host cannot reach it either, the result proves
        # nothing and is reported as inconclusive rather than as a pass.
        environment.systemPackages = [
            (pkgs.writeShellApplication {
                name          = "sarten-fwtest";
                runtimeInputs = [ config.virtualisation.incus.package pkgs.netcat pkgs.gawk pkgs.coreutils ];
                text = ''
                    image=images:alpine/3.24
                    names=(fwtest-inc fwtest-lab1 fwtest-lab2)
                    fail=0

                    trap 'incus delete -f "''${names[@]}" >/dev/null 2>&1 || true' EXIT

                    incus launch "$image" fwtest-inc  -q
                    incus launch "$image" fwtest-lab1 -q -p lab
                    incus launch "$image" fwtest-lab2 -q -p lab

                    addr() { incus list "$1" -c 4 -f csv | cut -d' ' -f1; }
                    for _ in $(seq 60); do
                        [ -n "$(addr fwtest-inc)" ] && [ -n "$(addr fwtest-lab1)" ] && [ -n "$(addr fwtest-lab2)" ] && break
                        sleep 2
                    done
                    inc=$(addr fwtest-inc); lab2=$(addr fwtest-lab2)
                    [ -n "$inc" ] && [ -n "$lab2" ] || { echo "FAIL no DHCP lease on a bridge"; exit 1; }

                    for c in fwtest-inc fwtest-lab2; do
                        incus exec "$c" -- sh -c 'nohup nc -lk -p 9000 -e /bin/true >/dev/null 2>&1 &'
                    done
                    sleep 1

                    probe() { # label instance want host port
                        local got=closed result
                        incus exec "$2" -- nc -z -w 4 "$4" "$5" >/dev/null 2>&1 && got=open
                        if [ "$got" != "$3" ]; then
                            result=FAIL; fail=1
                        elif [ "$3" = closed ] && ! nc -z -w 4 "$4" "$5" >/dev/null 2>&1; then
                            result=INCONCLUSIVE
                        else
                            result=PASS
                        fi
                        printf '%-12s %-12s %-40s want %-6s got %s\n' "$result" "$2" "$1 ($4:$5)" "$3" "$got"
                    }

                    for c in fwtest-inc fwtest-lab1; do
                        gw=$(incus exec "$c" -- ip route | awk '/default/ { print $3 }')
                        probe "wazuh agent"     "$c" open   "$gw" 1514
                        probe "wazuh enrolment" "$c" open   "$gw" 1515
                        probe "host sshd"       "$c" closed "$gw" 22
                        probe "wazuh dashboard" "$c" closed "$gw" 443
                        probe "homepage"        "$c" closed "$gw" 80
                        probe "docs"            "$c" closed "$gw" 8081
                        probe "incus api"       "$c" closed "$gw" 8443
                        probe "wazuh indexer"   "$c" closed "$gw" 9200
                        probe "host, LAN side"  "$c" closed ${lanAddr} 22
                        probe "LAN router"      "$c" closed ${config.networking.defaultGateway.address} 80
                        probe "host, tailnet"   "$c" closed "$(tailscale ip -4 2>/dev/null || echo 100.64.31.20)" 22
                    done
                    probe "internet"        fwtest-inc  open   1.1.1.1 443
                    probe "internet"        fwtest-lab1 closed 1.1.1.1 443
                    probe "same bridge"     fwtest-lab1 open   "$lab2" 9000
                    probe "lab to incusbr0" fwtest-lab1 closed "$inc"  9000
                    probe "incusbr0 to lab" fwtest-inc  closed "$lab2" 9000

                    exit "$fail"
                '';
            })
        ];
    };
}
