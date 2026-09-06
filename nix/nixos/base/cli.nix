{ ... }:
{
    flake.modules.nixos.cli = { pkgs, ... }: {
        environment.systemPackages = with pkgs; [
            bat
            bc
            chafa
            exiftool
            eza
            fd ripgrep
            ffmpeg-full ffmpegthumbnailer
            file
            fzf skim
            ghostty.terminfo
            htop btop
            hyperfine
            imagemagickBig
            inxi
            jq
            killall
            libqalculate
            lsof
            mediainfo
            ncdu
            ntfs3g
            pciutils
            poppler-utils
            pv
            rsync
            smartmontools
            starship
            superfile
            tmux tmuxp zellij
            tree
            unzip unar rar
            vim helix
            wget curl
            yazi lf
            yt-dlp
            zoxide

            # nix / dev
            cachix
            direnv nix-direnv
            python3

            # swag
            fastfetch pfetch-rs
            figlet lolcat
            tty-clock peaclock
        ];
    };
}
