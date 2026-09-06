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
