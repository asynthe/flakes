{ config, ... }: {

    boot.loader.grub = {
        efiSupport = true;
	efiInstallAsRemovable = true;
    };
}
