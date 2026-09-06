# Scanned on the box: no Smart Array on this ML350e, both drives are onboard AHCI.
{ ... }:
{
    flake.modules.nixos.sarten-hardware = { config, lib, modulesPath, ... }: {
        imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

        boot.initrd.availableKernelModules = [
            "ahci" "sd_mod" "sr_mod"
            "ehci_pci" "uhci_hcd" "usb_storage" "usbhid"
        ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-intel" ];   # 2x Xeon E5-2407
        boot.extraModulePackages = [ ];

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

        hardware.enableRedistributableFirmware = true;
        hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
