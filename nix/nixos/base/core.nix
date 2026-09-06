{ ... }:
{
    flake.modules.nixos.core = { ... }: {
        nixpkgs.config.allowUnfree = true;

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nix.settings.warn-dirty = false;
        nix.settings.auto-optimise-store = true;

        i18n.defaultLocale = "en_US.UTF-8";
        services.fstrim.enable = true;

        programs.zsh.enable = true;

        security.sudo.extraConfig = ''
            Defaults timestamp_timeout=120
            Defaults lecture = never
        '';
    };
}
