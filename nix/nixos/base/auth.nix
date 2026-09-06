{ lib, ... }:
let
    defaults = name: {
        admin       = false;
        passwordKey = "users/${name}";
        keys        = [];
    };

    people = lib.mapAttrs
        (name: person: defaults name // person)
        (import ../../../auth.nix);

    admins = lib.attrNames (lib.filterAttrs (_: person: person.admin) people);
in {
    flake.modules.nixos.auth = { config, lib, pkgs, ... }: {
        options.sys.admins = lib.mkOption {
            type        = lib.types.listOf lib.types.str;
            readOnly    = true;
            default     = admins;
            description = "Accounts in wheel, from auth.nix. Aspects add their groups to these.";
        };

        config = {
            users.users = lib.mapAttrs (name: person: {
                isNormalUser = true;
                shell        = pkgs.zsh;
                extraGroups  = lib.optional person.admin "wheel";

                openssh.authorizedKeys.keys = person.keys;

                hashedPasswordFile = lib.mkIf (person.passwordKey != null)
                    config.sops.secrets."password-${name}".path;
                hashedPassword = lib.mkIf (person.passwordKey == null) "!";
            }) people;

            sops.secrets = lib.mapAttrs' (name: person:
                lib.nameValuePair "password-${name}" {
                    key            = person.passwordKey;
                    neededForUsers = true;
                }
            ) (lib.filterAttrs (_: person: person.passwordKey != null) people);

            nix.settings.trusted-users = admins;
        };
    };
}
