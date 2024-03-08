{ config, ... }: {

    users.users."ben" = {
        isNormalUser = true;
        initialPassword = "1";
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    };
}
