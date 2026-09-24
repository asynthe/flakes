{ ... }:
{
    flake.modules.nixos.archive = { config, lib, ... }: {
        options.sys.archive = {
            dir = lib.mkOption {
                type        = lib.types.str;
                default     = "/srv/archive";
                description = "Root of the mirrored archive; the laptop is its source of truth";
            };

            group = lib.mkOption {
                type        = lib.types.str;
                default     = "media";
                description = "Group that may write the tree; must match `sys.arr.group` to share one gid";
            };

            trees = lib.mkOption {
                type        = lib.types.listOf lib.types.str;
                default     = [ "music" ];
                example      = [ "music" "anime" "book" ];
                description = ''
                    Subdirectories of `dir` the laptop mirrors into. Listing one
                    only creates it — nothing on this box ever writes there, and
                    an unlisted directory that already exists is left alone.
                '';
            };
        };

        config = let cfg = config.sys.archive; in {
            # 2775 so a file lands in `group` whoever pushed it, and o+rx so
            # jellyfin reads the tree without being in that group — the same
            # trade as the arr library, for the same reason.
            systemd.tmpfiles.rules =
                [ "d ${cfg.dir} 2775 root ${cfg.group} - -" ]
                ++ map (t: "d ${cfg.dir}/${t} 2775 root ${cfg.group} - -") cfg.trees;
        };
    };
}
