{ config, ... }: {

    imports = [
        
	./modules/console.nix
	./modules/disko.nix
	./modules/impermanence.nix
	./modules/pkgs.nix
	./modules/usr.nix

    ];
}
