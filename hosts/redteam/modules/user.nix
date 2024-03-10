{ config, ... }: {

    users.users."redteam" = {
        isNormalUser = true;
        initialPassword = "password"; # SECRET
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    };
}
