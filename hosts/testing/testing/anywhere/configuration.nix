{ config, lib, pkgs, ... }: {

    system.stateVersion = "23.11";
    services.openssh.enable = true;
    environment.systemPackages = map lib.lowPrio [ pkgs.curl pkgs.gitMinimal ];

}
