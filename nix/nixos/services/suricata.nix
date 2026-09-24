{ ... }:
{
    flake.modules.nixos.suricata = { config, lib, ... }: {
        options.sys.suricata = {
            interface = lib.mkOption {
                type        = lib.types.str;
                description = "Interface to watch; the lab bridge, not the uplink";
            };

            homeNet = lib.mkOption {
                type        = lib.types.str;
                description = "What counts as inside, in suricata's list syntax";
            };

            logDir = lib.mkOption {
                type        = lib.types.str;
                default     = "/var/log/suricata";
                description = "Where eve.json lands; the wazuh manager reads it from here";
            };
        };

        config = let cfg = config.sys.suricata; in {
            services.suricata = {
                enable = true;

                # nixpkgs builds suricata without the modbus and dnp3 parsers,
                # and a signature for a parser that is not there is a fatal
                # config error rather than a skipped rule: suricata refuses to
                # start at all. Matching on the rule text rather than on sids
                # keeps a later ruleset update from reintroducing it.
                disabledRules = lib.mkForce [
                    "re:app-layer-event: *(modbus|dnp3)"
                ];

                settings = {
                    default-log-dir = cfg.logDir;

                    vars.address-groups.HOME_NET = cfg.homeNet;

                    # defrag "no" is load-bearing, not a tuning choice: with the
                    # fanout DEFRAG flag on, capturing this bridge silently eats
                    # the DHCP OFFER back to instances and they never get a
                    # lease. Suricata still reassembles streams at the app layer.
                    af-packet = [{
                        interface    = cfg.interface;
                        cluster-id   = "99";
                        cluster-type = "cluster_flow";
                        defrag       = "no";
                    }];

                    # eve.json is the machine-readable one and the only output
                    # wazuh parses; fast.log is for reading by eye on the box.
                    outputs = [
                        {
                            eve-log = {
                                enabled      = true;
                                filetype     = "regular";
                                filename     = "eve.json";
                                community-id = true;
                                types = [
                                    { alert.tagged-packets = "yes"; }
                                    "http"
                                    "dns"
                                    "tls"
                                    "ssh"
                                    "flow"
                                ];
                            };
                        }
                        {
                            fast = {
                                enabled  = true;
                                filename = "fast.log";
                                append   = "yes";
                            };
                        }
                    ];
                };
            };

            # The manager runs in a container with no host paths bound in beyond
            # its own config, so the directory has to be readable from outside
            # suricata's user for the bind mount to be worth anything.
            systemd.tmpfiles.rules = [ "d ${cfg.logDir} 0755 suricata suricata - -" ];
        };
    };
}
