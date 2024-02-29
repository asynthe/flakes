{ config, pkgs, ... }: {

    networking.hostName = "server";
    system.stateVersion = "23.11";
    nixpkgs.config.allowUnfree = true;
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "Australia/Perth";

    imports = [

        ./modules.nix
	#./hardware.nix

	# Specific disk partitioning
	#../../disko/ext4_simple.nix
	#../../disko/bcachefs_simple.nix
	#../../disko/xfs_simple.nix
    ];
}
