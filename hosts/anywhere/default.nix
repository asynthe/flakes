{ modulesPath, config, ... }: {

    imports = [
        
	./configuration.nix
	./disk-config.nix
	(modulesPath + "/installer/scan/not-detected.nix")
	(modulesPath + "/profiles/qemu-guest.nix")

    ];
}
