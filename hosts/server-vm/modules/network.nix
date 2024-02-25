{ config, pkgs, ... }: {

    networking.networkmanager.enable = true;
    services = {
	tailscale.enable = true;
        openssh = {
            enable = true;
	    allowSFTP = true;
        };
    };
}
