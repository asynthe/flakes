{ ... }:
{
    flake.modules.nixos.arr = { config, lib, pkgs, ... }: {
        options.sys.arr = {
            mediaDir = lib.mkOption {
                type        = lib.types.str;
                default     = "/srv/media";
                description = "Library root; must match sys.jellyfin.mediaDir";
            };

            group = lib.mkOption {
                type        = lib.types.str;
                default     = "media";
                description = "Shared primary group for every service that writes to the library";
            };

            bind = lib.mkOption {
                type        = lib.types.str;
                default     = "127.0.0.1";
                description = "Address the arr web UIs bind to";
            };

            directorTag = lib.mkOption {
                type        = lib.types.str;
                default     = "dir-";
                description = "Radarr tag prefix that files a movie under Directors/ instead of General/";
            };

            directorNames = lib.mkOption {
                type        = lib.types.attrsOf lib.types.str;
                default     = { };
                example     = { "wong-kar-wai" = "Wong Kar-wai"; };
                description = ''
                    Folder names for tag slugs that title-casing gets wrong.
                    A slug not listed here becomes Title Case: the tag
                    `dir-denis-villeneuve` needs no entry, `dir-wong-kar-wai`
                    does.
                '';
            };

            syncInterval = lib.mkOption {
                type        = lib.types.str;
                default     = "15min";
                description = "Fallback reconcile interval; the path watch handles the prompt case";
            };

            openFirewall = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Open every arr UI port to the LAN; leave off when reaching them over ssh -L";
            };
        };

        config = let
            cfg = config.sys.arr;

            movies  = "${cfg.mediaDir}/movies";
            library = "${cfg.mediaDir}/library/movies";

            sync = pkgs.writers.writePython3Bin "arr-library-sync" {
                flakeIgnore = [ "E501" ];
            } ''
                """Reconcile the by-director symlink tree from Radarr's tags."""
                import json
                import os
                import urllib.request
                from xml.etree import ElementTree

                url = os.environ["RADARR_URL"].rstrip("/")
                tree = os.environ["LIBRARY_DIR"]
                prefix = os.environ["TAG_PREFIX"].lower()
                names = json.loads(os.environ["DIRECTOR_NAMES"])

                try:
                    key = ElementTree.parse(os.environ["RADARR_CONFIG"]).getroot().findtext("ApiKey")
                except (OSError, ElementTree.ParseError):
                    key = None
                if not key:
                    raise SystemExit("no ApiKey in radarr's config.xml yet")


                def api(path):
                    req = urllib.request.Request(url + "/api/v3/" + path, headers={"X-Api-Key": key})
                    with urllib.request.urlopen(req, timeout=30) as resp:
                        return json.load(resp)


                def display(slug):
                    return names.get(slug) or " ".join(w.capitalize() for w in slug.split("-"))


                tags = {t["id"]: t["label"].lower() for t in api("tag")}

                want = {}
                for movie in api("movie"):
                    path = movie.get("path")
                    if not movie.get("hasFile") or not path:
                        continue
                    target = os.path.normpath(path)
                    folder = os.path.basename(target)
                    directors = [display(tags[i][len(prefix):]) for i in movie.get("tags", [])
                                 if tags.get(i, "").startswith(prefix)]
                    for name in directors:
                        want[os.path.join("Directors", name, folder)] = target
                    if not directors:
                        want[os.path.join("General", folder)] = target

                have = {}
                for root, subdirs, files in os.walk(tree):
                    for entry in subdirs + files:
                        full = os.path.join(root, entry)
                        if os.path.islink(full):
                            have[os.path.relpath(full, tree)] = full

                for rel, link in have.items():
                    if want.get(rel) != os.readlink(link):
                        os.unlink(link)

                for rel, target in want.items():
                    link = os.path.join(tree, rel)
                    if os.path.islink(link):
                        continue
                    os.makedirs(os.path.dirname(link), exist_ok=True)
                    os.symlink(target, link)

                for root, subdirs, files in os.walk(tree, topdown=False):
                    if os.path.relpath(root, tree).count(os.sep) < 1:
                        continue
                    if not os.listdir(root):
                        os.rmdir(root)
            '';
        in {
            # ─────────────── Services ───────────────
            services.radarr = {
                enable       = true;
                group        = cfg.group;
                openFirewall = cfg.openFirewall;
                settings.server.bindaddress = cfg.bind;
            };

            services.sonarr = {
                enable       = true;
                group        = cfg.group;
                openFirewall = cfg.openFirewall;
                settings.server.bindaddress = cfg.bind;
            };

            services.lidarr = {
                enable       = true;
                group        = cfg.group;
                openFirewall = cfg.openFirewall;
                settings.server.bindaddress = cfg.bind;
            };

            services.prowlarr = {
                enable       = true;
                openFirewall = cfg.openFirewall;
                settings.server.bindaddress = cfg.bind;
            };

            services.bazarr = {
                enable       = true;
                group        = cfg.group;
                openFirewall = cfg.openFirewall;
            };

            # ─────────────── Library ───────────────
            users.groups.${cfg.group} = { };
            users.users = lib.genAttrs config.sys.admins
                (_: { extraGroups = [ cfg.group ]; });

            systemd.tmpfiles.rules = map (d: "d ${d} 2775 root ${cfg.group} - -") [
                movies
                "${cfg.mediaDir}/series"
                "${cfg.mediaDir}/anime"
                "${cfg.mediaDir}/music"
                "${cfg.mediaDir}/library"
                library
                "${library}/Directors"
                "${library}/General"
            ];

            # ─────────────── Symlink tree ───────────────
            systemd.services = {
                radarr.serviceConfig.UMask = lib.mkForce "0002";
                sonarr.serviceConfig.UMask = lib.mkForce "0002";
                lidarr.serviceConfig.UMask = lib.mkForce "0002";
                bazarr.serviceConfig.UMask = "0002";

                arr-library = {
                    description = "Reconcile the by-director movie tree Jellyfin scans";
                    after       = [ "radarr.service" ];

                    serviceConfig = {
                        Type      = "oneshot";
                        User      = "radarr";
                        Group     = cfg.group;
                        UMask     = "0002";
                        ExecStart = "${sync}/bin/arr-library-sync";
                    };

                    environment = {
                        RADARR_URL     = "http://127.0.0.1:${toString config.services.radarr.settings.server.port}";
                        RADARR_CONFIG  = "${config.services.radarr.dataDir}/config.xml";
                        LIBRARY_DIR    = library;
                        TAG_PREFIX     = cfg.directorTag;
                        DIRECTOR_NAMES = builtins.toJSON cfg.directorNames;
                    };
                };
            };

            systemd.paths.arr-library = {
                wantedBy = [ "multi-user.target" ];
                pathConfig.PathModified = movies;
            };

            systemd.timers.arr-library = {
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnBootSec       = "5min";
                    OnUnitActiveSec = cfg.syncInterval;
                };
            };
        };
    };
}
