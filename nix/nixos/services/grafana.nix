# Grafana, with the Prometheus datasource provisioned rather than clicked in.
{ ... }:
{
    flake.modules.nixos.grafana = { config, lib, pkgs, ... }: {
        options.sys.grafana = {
            bind = lib.mkOption {
                type        = lib.types.str;
                default     = "127.0.0.1";
                description = "Address the web UI binds to";
            };

            port = lib.mkOption {
                type        = lib.types.port;
                default     = 3000;
                description = "Web UI port";
            };

            datasource = lib.mkOption {
                type        = lib.types.str;
                default     = "http://127.0.0.1:9090";
                description = "Prometheus URL provisioned as the default datasource";
            };

            openFirewall = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Open the UI port to the LAN; leave off when reaching it over tailscale";
            };

            secretKeyFile = lib.mkOption {
                type        = lib.types.nullOr lib.types.path;
                default     = null;
                description = "File holding `secret_key`; one is generated on the host when null";
            };
        };

        config = let
            cfg     = config.sys.grafana;
            genPath = "/var/lib/grafana/secret_key";
            keyPath = if cfg.secretKeyFile != null then cfg.secretKeyFile else genPath;
        in {
            services.grafana = {
                enable = true;

                settings.server = {
                    http_addr = cfg.bind;
                    http_port = cfg.port;
                };

                # 26.05 refuses to start without one; local-only, so not in sops.
                settings.security.secret_key = "$__file{${keyPath}}";

                # Provisioned, so the datasource survives a wiped /var/lib/grafana.
                provision.datasources.settings.datasources = [{
                    name      = "Prometheus";
                    type      = "prometheus";
                    access    = "proxy";
                    url       = cfg.datasource;
                    isDefault = true;
                }];
            };

            systemd.services.grafana-secret-key = lib.mkIf (cfg.secretKeyFile == null) {
                requiredBy    = [ "grafana.service" ];
                before        = [ "grafana.service" ];
                path          = [ pkgs.coreutils ];
                serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
                script = ''
                    if [ ! -e ${genPath} ]; then
                        install -d -m 0750 -o grafana -g grafana /var/lib/grafana
                        ( umask 077; head -c 32 /dev/urandom | base64 -w0 > ${genPath} )
                        chown grafana:grafana ${genPath}
                        chmod 0400 ${genPath}
                    fi
                '';
            };

            networking.firewall.allowedTCPPorts =
                lib.mkIf cfg.openFirewall [ cfg.port ];
        };
    };
}
