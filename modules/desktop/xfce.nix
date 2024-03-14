{ config, pkgs, username, ... }: {

    services.xserver = {
        enable = true;	
        desktopManager = {
            xfce.enable = true;
	    xfce.enableScreensaver = true;
            xterm.enable = false;
	};
        displayManager = {
	    defaultSession = "xfce";
	    autoLogin = {
	        enable = true;
	        user = "${username}";
	    };
	};
    };
}
