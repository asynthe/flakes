{ ... }:
{
    flake.modules.nixos.boot-uefi = { pkgs, ... }: {
        environment.systemPackages = [ pkgs.efibootmgr ];

        boot.loader.efi.canTouchEfiVariables         = true;
        boot.loader.systemd-boot.enable              = true;
        boot.loader.systemd-boot.configurationLimit  = 3;
        boot.loader.timeout                          = 3;
    };

    # Legacy BIOS/CSM. The host still has to name a target disk in
    # `boot.loader.grub.devices`, which is a fact about its hardware.
    flake.modules.nixos.boot-bios = { ... }: {
        boot.loader.grub.enable             = true;
        boot.loader.grub.efiSupport         = false;
        boot.loader.grub.configurationLimit = 3;
        boot.loader.timeout                 = 3;
    };
}
