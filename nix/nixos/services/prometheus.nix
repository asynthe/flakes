{ ... }:
{
    flake.modules.nixos.node-exporter = { config, lib, ... }: {
        options.sys.exporters.bind = lib.mkOption {
            type        = lib.types.str;
            default     = "127.0.0.1";
            description = ''
                Address the exporters listen on. Loopback is right for the
                machine that also runs Prometheus; a machine being scraped
                remotely wants "0.0.0.0", which the tailnet firewall already
                fences off from the LAN.
            '';
        };

        config = {
            services.prometheus.exporters.node = {
                enable            = true;
                listenAddress     = config.sys.exporters.bind;
                enabledCollectors = [ "systemd" ];
            };

            services.prometheus.exporters.smartctl = {
                enable        = true;
                listenAddress = config.sys.exporters.bind;
            };

            networking.firewall.allowedTCPPorts =
                lib.mkIf (config.sys.exporters.bind != "127.0.0.1") [
                    config.services.prometheus.exporters.node.port
                    config.services.prometheus.exporters.smartctl.port
                ];
        };
    };

    flake.modules.nixos.prometheus = { config, lib, ... }: {
        options.sys.prometheus = {
            bind = lib.mkOption {
                type        = lib.types.str;
                default     = "127.0.0.1";
                description = "Address the server binds to";
            };

            port = lib.mkOption {
                type        = lib.types.port;
                default     = 9090;
                description = "Server listen port";
            };

            retention = lib.mkOption {
                type        = lib.types.str;
                default     = "90d";
                description = "How long samples are kept before compaction drops them";
            };

            openFirewall = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Open the server port to the LAN; leave off when reaching it over tailscale";
            };

            extraTargets = lib.mkOption {
                type        = lib.types.listOf lib.types.str;
                default     = [];
                example     = [ "p1:9100" ];
                description = "Further `host:port` node exporters to scrape alongside this machine";
            };
        };

        config = let
            cfg   = config.sys.prometheus;
            node  = config.services.prometheus.exporters.node;
            smart = config.services.prometheus.exporters.smartctl;
        in {
            services.prometheus = {
                enable        = true;
                listenAddress = cfg.bind;
                port          = cfg.port;
                retentionTime = cfg.retention;

                globalConfig.scrape_interval = "30s";

                scrapeConfigs = [
                    {
                        job_name = "node";
                        static_configs = [{
                            targets = [ "127.0.0.1:${toString node.port}" ] ++ cfg.extraTargets;
                        }];
                    }
                    {
                        job_name = "smartctl";
                        static_configs = [{ targets = [ "127.0.0.1:${toString smart.port}" ]; }];
                    }
                ];
            };

            networking.firewall.allowedTCPPorts =
                lib.mkIf cfg.openFirewall [ cfg.port ];
        };
    };
}
