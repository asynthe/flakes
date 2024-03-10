{ config, ... }: {

    users.users."missingno" = {
        isNormalUser = true;
        initialPassword = "password"; # SECRET
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
        openssh.authorizedKeys.keys = [ # SECRET
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIY8tUQ59AvWkt0pTSMz2bf3O7emcO37IaA8vZCnXisk bendunstan@protonmail.com"
        ];
    };

    users.users."vercelperc" = {
        isNormalUser = true;
        initialPassword = "password"; # SECRET
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    };

    users.users.root.openssh.authorizedKeys.keys = [ # SECRET
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIY8tUQ59AvWkt0pTSMz2bf3O7emcO37IaA8vZCnXisk bendunstan@protonmail.com"
    ];
}
