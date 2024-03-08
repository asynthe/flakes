{ config, lib, pkgs, ... }: {

  system.stateVersion = "23.11";
  services.openssh.enable = true;

  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  #boot.loader.grub.devices = [ ]; # no need to set devices, disko will add all devices that have a EF02 partition to the list already

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];
  
  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIY8tUQ59AvWkt0pTSMz2bf3O7emcO37IaA8vZCnXisk bendunstan@protonmail.com"
  ];
}
