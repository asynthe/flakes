{ config, pkgs, ... }: {

    services.openssh.enable = true;

    # XFCE
    services.xserver.desktopManager.xfce = {
        enable = true;
	enableScreensaver = true;
    };

    programs = {
        thunar.enable = true;
	xfconf.enable = true;
    };
}
