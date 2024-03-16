{ config, pkgs, ... }: {

    services.openssh.enable = true;

    # Nix Settings
    nix.allowedUsers = [ "root" ]; # Everyone but root can use nix.

}
