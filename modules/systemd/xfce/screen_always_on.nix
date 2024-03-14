{ config, lib, pkgs, ... }: {

    services.logind = {
        extraConfig = ''
            HandleSuspendKey=ignore
            HandleLidSwitch=ignore
            HandleHibernateKey=ignore
        '';
    };

    systemd.user.services.disable-screen-blanking = {
        description = "Disable screen blanking, DPMS, and XFCE screen lock";
        wantedBy = [ "graphical-session.target" ]; # Run after X starts.
        path = with pkgs; [ xorg.xset xfce.xfconf ];
        script = ''
            # Wait for X server
            while ! xset q &>/dev/null; do
              sleep 1
            done
        
	    # Disable screen saver, screen blank, and DPMS
            xset s off
            xset s noblank
            xset -dpms

	    # Disable XFCE screen lock
	    xfconf-query -c xfce4-screensaver -p /saver/idle-activation-enabled -s false
        '';
    };
}
