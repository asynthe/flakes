# Server-shaped networking: no wireless backend, no MAC randomisation. A machine
# with wifi wants its own aspect alongside this one.
{ ... }:
{
    flake.modules.nixos.net-base = { ... }: {
        networking.nftables.enable = true;

        services.resolved = {
            enable = true;
            settings.Resolve.FallbackDNS = [ "1.1.1.1" "1.0.0.1" ];
        };
    };
}
