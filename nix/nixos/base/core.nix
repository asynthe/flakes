# Imported by every machine: nix daemon settings, the primary user, locale.
{ ... }:
{
    flake.modules.nixos.core = { config, pkgs, ... }: {
        nixpkgs.config.allowUnfree = true;

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nix.settings.warn-dirty = false;
        nix.settings.auto-optimise-store = true;

        i18n.defaultLocale = "en_US.UTF-8";
        services.fstrim.enable = true;

        # Shell
        programs.zsh.enable = true;
        users.users.${config.sys.user} = {
            shell = pkgs.zsh;
            isNormalUser = true;
            extraGroups = [ "wheel" ];
        };

        security.sudo.extraConfig = ''
            # Ask for password every 2 hours
            Defaults timestamp_timeout=120
            # rollback results in sudo lectures after each reboot
            Defaults lecture = never
        '';
    };
}
