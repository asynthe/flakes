# Importing this is what makes `deploy .#<host>` work against a machine; the
# target itself is stated in `sys.deploy.*`.
{ ... }:
{
    flake.modules.nixos.deploy = { config, lib, ... }: {
        config = {
            sys.deploy.enabled = true;

            # deploy-rs sudos from sshUser to `user` non-interactively, so a
            # password prompt there does not fail, it hangs until the timeout.
            # Scoped to the one account, which is already key-only over ssh.
            security.sudo.extraRules =
                lib.mkIf (config.sys.deploy.sshUser != "root") [{
                    users    = [ config.sys.deploy.sshUser ];
                    runAs    = config.sys.deploy.user;
                    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
                }];

            # Lets the deployer push a closure it built and never signed.
            nix.settings.trusted-users = [ config.sys.deploy.sshUser ];
        };
    };
}
