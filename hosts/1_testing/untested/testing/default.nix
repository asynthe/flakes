{ config, ... }: {

    networking.hostName = "";
    system.stateVersion = "23.11";
    nixpkgs.config.allowUnfree = true;
    i18n.defaultLocale = "en_US.UTF-8";
    time.timeZone = "Australia/Perth";

    # Configuration to move
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    services.openssh.enable = true;
    #programs.fuse.userAllowOther = true;
    #home-manager = {
      #extraSpecialArgs = {inherit inputs;};
      #users = {
        #"vimjoyer" = import ./home.nix;
      #};
    #};

    imports = [
        
	./modules.nix
	./hardware.nix

    ];
}
