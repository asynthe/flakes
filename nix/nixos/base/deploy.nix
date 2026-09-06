{ ... }:
{
    flake.modules.nixos.deploy = { config, lib, ... }: {
        config = {
            sys.deploy.enabled = true;

            security.sudo.extraRules =
                lib.mkIf (config.sys.deploy.sshUser != "root") [{
                    users    = [ config.sys.deploy.sshUser ];
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
