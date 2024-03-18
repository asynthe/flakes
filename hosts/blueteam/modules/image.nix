{ config, pkgs, ... }: {

    users.users.root.password = "pw123";
    users.mutableUsers = true; # ?

    # Grub
    boot.loader.timeout = 5;

}
