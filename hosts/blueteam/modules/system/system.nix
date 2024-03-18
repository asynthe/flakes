{ config, pkgs, ... }: {

    services.openssh.enable = true;

    # Required by nixos-generators ?
    nix.settings.system-features = [ "kvm" ];

    # Nix Settings
    nix.settings.allowed-users = [ "root" ]; # Everyone but root can use nix.

}
