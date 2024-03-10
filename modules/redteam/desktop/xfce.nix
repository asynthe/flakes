{ config, pkgs, ... }: {

    displayManager.defaultSession = "xfce";
    services.xserver = {
        enable = true;	
        desktopManager = {
            xfce.enable = true;
            xterm.enable = false;
	};
    };
}
