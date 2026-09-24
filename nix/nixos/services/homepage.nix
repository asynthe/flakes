{ ... }:
{
    flake.modules.nixos.homepage = { config, lib, pkgs, ... }: {
        options.sys.homepage = {
            port = lib.mkOption {
                type        = lib.types.port;
                default     = 8082;
                description = "Port the dashboard listens on";
            };

            host = lib.mkOption {
                type        = lib.types.str;
                default     = "localhost";
                example     = "sarten";
                description = "Hostname the service tiles link to";
            };

            openFirewall = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Put the dashboard on the LAN; the tiles still point at `host`";
            };

            proxy = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Put nginx on port 80 in front and open it, so `http://<host>` is the dashboard";
            };

            backgrounds = lib.mkOption {
                type        = lib.types.listOf lib.types.path;
                default     = [];
                description = "Wallpapers; one is picked at random on each page load";
            };
        };

        config = let
            cfg  = config.sys.homepage;
            at   = p: "http://${cfg.host}:${toString p}";
            port = toString cfg.port;

            shrink = img: pkgs.runCommand "homepage-bg-${baseNameOf img}"
                { nativeBuildInputs = [ pkgs.imagemagick ]; }
                "magick ${img} -resize 1600x -quality 72 -strip $out";

            dataUri = img: "data:image/jpeg;base64,${
                builtins.readFile (pkgs.runCommand "homepage-bg-b64" { } ''
                    base64 -w0 ${shrink img} | tr -d '\n' > $out
                '')
            }";
        in {
            services.homepage-dashboard = {
                enable       = true;
                listenPort   = cfg.port;
                openFirewall = cfg.openFirewall;
                allowedHosts = "${cfg.host}:${port},localhost:${port},127.0.0.1:${port}";

                settings = {
                    title       = cfg.host;
                    headerStyle = "boxed";
                    theme       = "dark";
                    color       = "slate";
                } // lib.optionalAttrs (cfg.backgrounds != []) {
                    background = {
                        image      = dataUri (builtins.head cfg.backgrounds);
                        blur       = "sm";
                        saturate   = 60;
                        brightness = 70;
                        opacity    = 75;
                    };
                };

                customCSS = ''
                    html, body {
                        background-color: #000 !important;
                    }
                    #page_container, #information-widgets {
                        background-color: transparent !important;
                    }
                    .services-group, .bookmark-group,
                    div[class*="bg-theme-"], div[class*="bg-white"] {
                        background-color: rgba(0, 0, 0, 0.55) !important;
                        backdrop-filter: blur(8px);
                    }
                '';

                customJS = lib.mkIf (cfg.backgrounds != []) ''
                    (() => {
                      const imgs = [
                    ${lib.concatMapStringsSep ",\n" (i: ''    "${dataUri i}"'') cfg.backgrounds}
                      ];
                      const pick = imgs[(Math.random() * imgs.length) | 0];
                      const apply = () => {
                        const el = document.getElementById("background");
                        if (!el) return false;
                        el.style.backgroundImage =
                          "linear-gradient(rgb(var(--bg-color) / 0.25), rgb(var(--bg-color) / 0.25)), url(\"" + pick + "\")";
                        el.style.backgroundSize = "cover";
                        el.style.backgroundPosition = "center";
                        return true;
                      };
                      // Next.js may not have painted #background yet.
                      if (!apply()) {
                        const o = new MutationObserver(() => { if (apply()) o.disconnect(); });
                        o.observe(document.documentElement, { childList: true, subtree: true });
                      }
                    })();
                '';

                widgets = [
                    { resources = { cpu = true; memory = true; disk = "/srv/media"; }; }
                    { datetime.format.timeStyle = "short"; }
                ];

                services = [
                    {
                        "Media" = [
                            { "Jellyfin" = { href = at 8096;
                                             description = "Library on tank/media"; }; }
                            { "Radarr"   = { href = at config.services.radarr.settings.server.port;
                                             description = "Movies"; }; }
                            { "Sonarr"   = { href = at config.services.sonarr.settings.server.port;
                                             description = "Series + anime"; }; }
                            { "Lidarr"   = { href = at config.services.lidarr.settings.server.port;
                                             description = "Music"; }; }
                            { "Prowlarr" = { href = at config.services.prowlarr.settings.server.port;
                                             description = "Indexers"; }; }
                            { "Bazarr"   = { href = at config.services.bazarr.listenPort;
                                             description = "Subtitles"; }; }
                            { "qBittorrent" = { href = at config.sys.qbittorrent.webuiPort;
                                                description = "Downloads"; }; }
                        ];
                    }
                    {
                        "Monitoring" = [
                            { "Grafana"    = { href = at config.sys.grafana.port;
                                               description = "Dashboards"; }; }
                            { "Prometheus" = { href = at config.sys.prometheus.port;
                                               description = "Metrics + targets"; }; }
                            { "Docs"       = { href = at config.sys.docs.port;
                                               description = "How this box works"; }; }
                        ];
                    }
                    {
                        "Infrastructure" = [{
                            "Incus" = {
                                href        = "https://${cfg.host}:8443";
                                description = "VMs and containers";
                            };
                        }];
                    }
                    {
                        "Security" = [{
                            "Wazuh" = {
                                href        = "https://${cfg.host}:${toString config.sys.wazuh.dashboardPort}";
                                description = "SIEM dashboard";
                            };
                        }];
                    }
                ];
            };

            services.nginx = lib.mkIf cfg.proxy {
                enable                   = true;
                recommendedProxySettings = true;

                virtualHosts.${cfg.host} = {
                    default = true;
                    locations."/" = {
                        proxyPass       = "http://127.0.0.1:${port}";
                        proxyWebsockets = true;

                        # Rewriting Host is why this is spelled out instead of
                        # `recommendedProxySettings`: reached by LAN name, by IP or
                        # over the tailnet, the dashboard sees the one host it allows.
                        recommendedProxySettings = false;
                        extraConfig = ''
                            proxy_set_header Host              ${cfg.host}:${port};
                            proxy_set_header X-Real-IP         $remote_addr;
                            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
                            proxy_set_header X-Forwarded-Proto $scheme;
                        '';
                    };
                };
            };

            networking.firewall.allowedTCPPorts = lib.mkIf cfg.proxy [ 80 ];
        };
    };
}
