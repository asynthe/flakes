# Imported by every machine: nix daemon settings, locale. Accounts come from the
# `auth` aspect.
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
            # Ask for password every 2 hours
            Defaults timestamp_timeout=120
            # rollback results in sudo lectures after each reboot
            Defaults lecture = never
        '';
    };
}
