# Headless qbittorrent-nox behind the `arr` aspect. `downloadDir` must stay under
# the media root or hardlink imports become copies. See docs/MEDIA.md.
{ ... }:
{
    flake.modules.nixos.qbittorrent = { config, lib, pkgs, ... }: {
        options.sys.qbittorrent = {
            downloadDir = lib.mkOption {
                type        = lib.types.str;
                default     = "/srv/media/downloads";
                description = "Save path; must be on the same filesystem as the arr root folders";
            };

            group = lib.mkOption {
                type        = lib.types.str;
                default     = "media";
                description = "Shared primary group; must match sys.arr.group";
            };

            bind = lib.mkOption {
                type        = lib.types.str;
                default     = "127.0.0.1";
                description = "Address the web UI binds to";
            };

            webuiPort = lib.mkOption {
                type        = lib.types.port;
                default     = 8080;
                description = "Web UI port";
            };

            torrentPort = lib.mkOption {
                type        = lib.types.port;
                default     = 6881;
                description = "Port peers connect in on";
            };

            openTorrentPort = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = ''
                    Open torrentPort to the LAN. Useless on its own -- incoming
                    peers arrive from the internet, so this needs a matching
                    forward on the router. Outgoing connections work without it.
                '';
            };

            openFirewall = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Open the web UI port to the LAN; leave off when reaching it over ssh -L";
            };
        };

        config = let
            cfg = config.sys.qbittorrent;

            profile = config.services.qbittorrent.profileDir;

            # One category per arr, seeded once with `C` because the UI rewrites this file.
            categories = {
                radarr         = { save_path = "${cfg.downloadDir}/movies"; };
                sonarr         = { save_path = "${cfg.downloadDir}/series"; };
                "sonarr-anime" = { save_path = "${cfg.downloadDir}/anime"; };
                lidarr         = { save_path = "${cfg.downloadDir}/music"; };
            };

            categoriesFile =
                (pkgs.formats.json { }).generate "qbittorrent-categories.json" categories;
        in {
            services.qbittorrent = {
                enable         = true;
                group          = cfg.group;
                webuiPort      = cfg.webuiPort;
                torrentingPort = cfg.torrentPort;
                openFirewall   = false;   # handled below, per port

                # Rewritten on every start: change these four here, not in the web UI.
                serverConfig = {
                    LegalNotice.Accepted = true;

                    BitTorrent.Session = {
                        DefaultSavePath = cfg.downloadDir;
                        Port            = cfg.torrentPort;
                    };

                    Preferences.WebUI = {
                        Address = cfg.bind;
                        Port    = cfg.webuiPort;

                        # No password: the UI is firewalled to ssh reach only, and the arrs need the API.
                        LocalHostAuth = false;
                    };
                };
            };

            users.groups.${cfg.group} = { };

            # 0002 so the arrs can hardlink out and clean up once seeding stops.
            systemd.services.qbittorrent.serviceConfig.UMask = "0002";

            systemd.tmpfiles.rules =
                map (d: "d ${d} 2775 qbittorrent ${cfg.group} - -") [
                    cfg.downloadDir
                    "${cfg.downloadDir}/movies"
                    "${cfg.downloadDir}/series"
                    "${cfg.downloadDir}/anime"
                    "${cfg.downloadDir}/music"
                ];

            # Merged into the module's tmpfiles key so it is ordered after its `d` lines.
            systemd.tmpfiles.settings.qbittorrent."${profile}/qBittorrent/config/categories.json".C = {
                argument = "${categoriesFile}";
                user     = "qbittorrent";
                group    = cfg.group;
                mode     = "0664";
            };

            networking.firewall = {
                allowedTCPPorts =
                    lib.optional cfg.openFirewall cfg.webuiPort
                    ++ lib.optional cfg.openTorrentPort cfg.torrentPort;
                allowedUDPPorts = lib.optional cfg.openTorrentPort cfg.torrentPort;
            };
        };
    };
}
