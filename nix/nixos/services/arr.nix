# The *arr stack plus the by-director symlink tree Jellyfin scans. See docs/MEDIA.md.
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

            # Radarr keeps `movies` flat; `library` is generated and is what Jellyfin scans.
            movies  = "${cfg.mediaDir}/movies";
            library = "${cfg.mediaDir}/library/movies";

            # Radarr stores no crew, so the tree is driven by `dir-<name>` tags.
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

                # Radarr writes its api key into config.xml on first start; absent before that.
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

                # Reconciled, not rebuilt: a churning tree makes Jellyfin rescan every run.
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

                # A retagged movie leaves its old Directors/<name> behind; tmpfiles owns the buckets.
                for root, subdirs, files in os.walk(tree, topdown=False):
                    if os.path.relpath(root, tree).count(os.sep) < 1:
                        continue
                    if not os.listdir(root):
                        os.rmdir(root)
            '';
        in {
            # ─────────────── Services ───────────────
            # `group` is overridden, not `user`: separate uids and state, shared library access.
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

            # Talks to trackers, never the library, so it keeps DynamicUser.
            services.prowlarr = {
                enable       = true;
                openFirewall = cfg.openFirewall;
                settings.server.bindaddress = cfg.bind;
            };

            # Needs the group to write subtitles; has no bind option, it reads its own config.ini.
            services.bazarr = {
                enable       = true;
                group        = cfg.group;
                openFirewall = cfg.openFirewall;
            };

            # ─────────────── Library ───────────────
            users.groups.${cfg.group} = { };
            users.users.${config.sys.user}.extraGroups = [ cfg.group ];

            # Setgid keeps files in the group whoever writes them; the media root is jellyfin's.
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
                # The modules hardcode 0022, which would strip group write from imports.
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
                        # Loopback whatever `bind` says: a wildcard is not a valid host.
                        RADARR_URL     = "http://127.0.0.1:${toString config.services.radarr.settings.server.port}";
                        RADARR_CONFIG  = "${config.services.radarr.dataDir}/config.xml";
                        LIBRARY_DIR    = library;
                        TAG_PREFIX     = cfg.directorTag;
                        DIRECTOR_NAMES = builtins.toJSON cfg.directorNames;
                    };
                };
            };

            # The path unit catches imports; the timer catches tags, which touch no file.
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
