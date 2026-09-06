{ ... }:
{
    flake.modules.nixos.tailscale = { config, ... }: {
        services.tailscale.enable = true;
        networking.firewall = {
            enable = true;
            trustedInterfaces = [ config.services.tailscale.interfaceName ];
            allowedUDPPorts = [ config.services.tailscale.port ];
        };

        networking.nftables.enable = true;
        systemd.services.tailscaled.serviceConfig.Environment = [
            "TS_DEBUG_FIREWALL_MODE=nftables"
        ];

        networking.interfaces.tailscale0.useDHCP = false;

        systemd.network.wait-online.enable = false;
        boot.initrd.systemd.network.wait-online.enable = false;
    };
}
