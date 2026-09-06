{ inputs, ... }:
{
    flake.modules.nixos.gpg = { pkgs, ... }: {
        # Changing pinentry needs a `pkill gpg-agent` to take effect.
        programs.gnupg.agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-curses;
        };
    };

    # The sops-nix wiring only. Per-user password secrets belong to `auth`.
    flake.modules.nixos.sops = { config, lib, pkgs, ... }: {
        imports = [ inputs.sops-nix.nixosModules.sops ];

        # Outside /home, which is not guaranteed mounted when activation unlocks passwords.
        options.sys.sops.ageKeyFile = lib.mkOption {
            type        = lib.types.str;
            default     = "/var/lib/sops/age-keys.txt";
            description = ''
                Private age identity used to decrypt secrets/secrets.yaml. Must
                exist before the first activation -- nixos-anywhere puts it
                there with --extra-files.
            '';
        };

        options.sys.sops.rootPassword = lib.mkOption {
            type        = lib.types.bool;
            default     = false;
            description = ''
                Give root the same hash as the first admin in auth.nix, so `su`
                works. Grants nothing new: that account is in wheel and already
                sudos to root.
            '';
        };

        config = {
            environment.systemPackages = [ pkgs.sops pkgs.age ];
            sops.defaultSopsFile = ../../../secrets/secrets.yaml;
            sops.age.keyFile = config.sys.sops.ageKeyFile;
            sops.age.sshKeyPaths = [];   # don't fall back to the host key
            sops.gnupg.sshKeyPaths = [];

            users.users.root.hashedPasswordFile =
                lib.mkIf config.sys.sops.rootPassword
                    config.sops.secrets."password-${lib.head config.sys.admins}".path;
        };
    };
}
