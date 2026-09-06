{ ... }:
{
    flake.modules.nixos.jellyfin = { config, lib, ... }: {
        options.sys.jellyfin = {
            mediaDir = lib.mkOption {
                type        = lib.types.str;
                default     = "/srv/media";
                description = "Library root, readable by the jellyfin user";
            };

            openFirewall = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Open 8096/8920 to the LAN; leave off when reaching it over tailscale";
            };
        };

        config = {
            services.jellyfin = {
                enable       = true;
                openFirewall = config.sys.jellyfin.openFirewall;
            };

            systemd.tmpfiles.rules = [
                "d ${config.sys.jellyfin.mediaDir} 0775 jellyfin jellyfin - -"
            ];

            users.users = lib.genAttrs config.sys.admins
                (_: { extraGroups = [ "jellyfin" ]; });
        };
    };
}
