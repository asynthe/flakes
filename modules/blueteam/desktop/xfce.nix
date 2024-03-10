{ config, pkgs, user, ... }: {

    displayManager.defaultSession = "xfce";
    services.xserver = {
        enable = true;	
        desktopManager = {
            xfce.enable = true;
	    xfce.enableScreensaver = true;
            xterm.enable = false;
	};
	displayManager.autoLogin = {
	    enable = true;
	    user = "${user}";
	};
    };
}
