{ ... }:
{
    flake.modules.nixos.boot-uefi = { pkgs, ... }: {
        environment.systemPackages = [ pkgs.efibootmgr ];

        boot.loader.efi.canTouchEfiVariables         = true;
        boot.loader.systemd-boot.enable              = true;
        boot.loader.systemd-boot.configurationLimit  = 3;
        boot.loader.timeout                          = 3;
    };

    flake.modules.nixos.boot-bios = { ... }: {
        boot.loader.grub.enable             = true;
        boot.loader.grub.efiSupport         = false;
        boot.loader.grub.configurationLimit = 3;
        boot.loader.timeout                 = 3;
    };
}
