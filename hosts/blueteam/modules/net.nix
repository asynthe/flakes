{ config, pkgs, ... }: {

    networking.firewall.enable = true;

    # Tailscale
    #services.tailscale.enable = true;
    #networking.firewall.trustedInterfaces = [ "tailscale0" ];

}
