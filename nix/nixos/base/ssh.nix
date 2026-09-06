# The daemon only. Which keys open it is auth.nix's business.
{ ... }:
{
    flake.modules.nixos.ssh = { config, lib, ... }: {
        config = let
            # The first key added is what closes the door, never a rebuild.
            hasKeys = lib.any
                (name: config.users.users.${name}.openssh.authorizedKeys.keys != [])
                config.sys.admins;
        in {
            services.openssh = {
                enable = true;
                settings = {
                    PasswordAuthentication       = !hasKeys;
                    KbdInteractiveAuthentication = !hasKeys;
                    PermitRootLogin              = "no";
                };
            };
        };
    };
}
