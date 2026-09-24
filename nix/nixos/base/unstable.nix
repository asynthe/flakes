{ inputs, ... }:
{
    flake.modules.nixos.core = { config, ... }: {
        nixpkgs.overlays = [
            (_: _: {
                unstable = import inputs.nixpkgs-unstable {
                    inherit (config.nixpkgs) config;
                    system = config.nixpkgs.hostPlatform.system;
                };
            })
        ];
    };
}
