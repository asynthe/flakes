{ ... }:
{
    flake.modules.nixos.git = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
            git
            git-lfs
            jujutsu
        ];
    };

    flake.modules.nixos.neovim = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
            neovim

            # core
            git
            gcc
            nodejs

            # search
            ripgrep
            fd

            # files
            yazi

            # lsp
            nixd
            bash-language-server
            pyright
            lua-language-server
            marksman
            yaml-language-server

            # formatters
            nixfmt
            shfmt
            stylua
        ];
    };
}
