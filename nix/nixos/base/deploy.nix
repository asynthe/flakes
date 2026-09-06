{ ... }:
{
    flake.modules.nixos.deploy = { config, lib, ... }: {
        config = {
            sys.deploy.enabled = true;

            security.sudo.extraRules = [{
                users    = config.sys.admins;
                runAs    = config.sys.deploy.user;
                commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
            }];

            nix.settings.trusted-users =
                lib.optional
                    (!lib.elem config.sys.deploy.sshUser config.sys.admins)
                    config.sys.deploy.sshUser;
        };
    };
}
