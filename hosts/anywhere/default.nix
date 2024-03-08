{ modulesPath, config, ... }: {

    imports = [
        
	# Example nixos-anywhere disko config
	./disko/example-config.nix

	# Impermanence
	#./disko/impermanence-config.nix
	#./disko/impermanence-module.nix

	./configuration.nix
	./qemu.nix
	(modulesPath + "/installer/scan/not-detected.nix")
	(modulesPath + "/profiles/qemu-guest.nix")

    ];
}
