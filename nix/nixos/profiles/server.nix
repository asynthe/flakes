# What every machine in this repo is before it is anything in particular.
# A host imports this and then names only what it actually serves.
{ config, ... }:
{
    flake.modules.nixos.profile-server = {
        imports = with config.flake.modules.nixos; [
            core cli
            net-base ssh
            auth sops deploy
            tailscale
            git neovim nh
            node-exporter smartd
        ];
    };
}
