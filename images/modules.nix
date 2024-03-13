{ config, pkgs, ... }: {

    imports = [
        
	../modules/images/nix_settings.nix
	../modules/images/ssh.nix
	../modules/images/user.nix

    ];
};
