# The home server: an HP ProLiant ML350e Gen8 v2, adopted in place. See docs/SARTEN.md.
{ config, ... }:
{
    flake.modules.nixos.host-sarten = { pkgs, ... }: {

        imports = with config.flake.modules.nixos; [
            profile-server
            sarten-hardware sarten-filesystems

            # ─────────────── System ───────────────
            boot-bios gpg

            # ─────────────── AI ───────────────
            hermes

            # ─────────────── Media ───────────────
            jellyfin
            arr qbittorrent

            # ─────────────── Monitoring ───────────────
            prometheus grafana homepage
            docker wazuh wazuh-syslog

            # ─────────────── Virtualisation ───────────────
            incus
        ];

        # ─────────────── Identity ───────────────
        system.nixos.label = "sarten";
        system.name = "sarten";
        networking.hostName = "sarten";
        system.stateVersion = "26.05";   # what the box was installed with; do not bump
        time.timeZone = "America/Santiago";

        sys.user = "meow";

        # `su` as well as `sudo -i`; same hash as meow.
        sys.sops.rootPassword = true;

        # Key-only, no password, not in wheel: can ssh in but cannot sudo or su.
        users.users.user = {
            isNormalUser = true;
            shell = pkgs.zsh;
        };
        sys.ssh.extraUsers = [ "user" ];

        # A non-empty list switches password auth off; losing p1's key locks the box.
        sys.ssh.authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0H7gtdrNpsghM6LQ3jPDoeDkJMQW4/YDfc+DzMF1/j meow@p1"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDnUPjUAi2Red+yEOocv3LorVYbA3VHTI6z4QjGX+9T s24"
        ];

        # ─────────────── Network ───────────────
        networking.useDHCP = false;
        networking.interfaces.eno1.ipv4.addresses = [
            { address = "192.168.1.135"; prefixLength = 24; }
        ];
        networking.defaultGateway = "192.168.1.1";
        networking.nameservers = [ "192.168.1.1" "1.1.1.1" ];

        # ─────────────── Deploy ───────────────
        # Over the tailnet, so a LAN or firewall change cannot strand the deploy.
        sys.deploy.hostname = "sarten";

        # ─────────────── Services ───────────────
        sys.hermes.dashboard   = true;
        sys.hermes.bind        = "sarten";
        sys.hermes.waitForHost = true;

        sys.jellyfin.mediaDir = "/srv/media";

        # Bound wide but not exposed: the firewall drops these on eno1, tailnet only.
        sys.grafana.bind     = "0.0.0.0";
        sys.prometheus.bind  = "0.0.0.0";
        sys.arr.bind         = "0.0.0.0";
        sys.qbittorrent.bind = "0.0.0.0";

        # Both the tile links and homepage's own Host check are built from this.
        sys.homepage.host = "sarten";

        sys.homepage.backgrounds = [
            ../../../assets/backgrounds/anime_frieren_field.jpg
            ../../../assets/backgrounds/anime_your_name_comet.jpg
            ../../../assets/backgrounds/anime_window_city_bw.jpg
            ../../../assets/backgrounds/abstract_eva01_teal.jpg
        ];

        # Only director names that title-casing mangles need an entry here.
        sys.arr.directorNames = {
            "wong-kar-wai" = "Wong Kar-wai";
        };

        # ─────────────── Incus ───────────────
        # Incus creates tank/incus itself, so nothing is declared in filesystems.nix.
        virtualisation.incus.ui.enable = true;
        virtualisation.incus.preseed = {
            config."core.https_address" = "0.0.0.0:8443";

            storage_pools = [{
                name   = "default";
                driver = "zfs";
                config.source = "tank/incus";
            }];

            networks = [
                # NAT'd, has a route out.
                {
                    name = "incusbr0";
                    type = "bridge";
                    config = {
                        "ipv4.address" = "auto";
                        "ipv6.address" = "none";
                    };
                }

                # Pentest targets: no NAT and no uplink, so they reach only each other.
                {
                    name = "labbr0";
                    type = "bridge";
                    config = {
                        "ipv4.address" = "10.66.66.1/24";
                        "ipv4.nat"     = "false";
                        "ipv4.dhcp"    = "true";
                        "ipv6.address" = "none";
                    };
                }
            ];

            profiles = [
                {
                    name = "default";
                    devices = {
                        root = { path = "/"; pool = "default"; type = "disk"; };
                        eth0 = { name = "eth0"; network = "incusbr0"; type = "nic"; };
                    };
                }

                # `incus launch <img> victim -p lab` lands on the isolated segment only.
                {
                    name = "lab";
                    devices = {
                        root = { path = "/"; pool = "default"; type = "disk"; };
                        eth0 = { name = "eth0"; network = "labbr0"; type = "nic"; };
                    };
                }
            ];
        };

        # ─────────────── Kernel ───────────────
        boot.supportedFilesystems = [ "ext4" "zfs" ];

        # ZFS refuses to import a pool without one; taken from /etc/machine-id.
        networking.hostId = "6d68b7e4";
    };
}
