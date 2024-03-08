{ config, pkgs, ... }: {

    networking.hostName = "paranoid";
    services.openssh.enable = true;

    networking.firewall.enable = true;
    
    # Trust packets routed over Tailscale
    networking.firewall.trustedInterfaces = [ "tailscale0" ];


}
