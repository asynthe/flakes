{ config, pkgs, ... }: {

    # NETWORKING
    networking.hostName = "paranoid";
    networking.firewall.enable = true;
    networking.firewall.trustedInterfaces = [ "tailscale0" ]; # Trust packets routed over Tailscale

    # NIX
    nix.allowedUsers = [ "root" ];

    # SSH AND USERS
    services.openssh.enable = true;
    services.openssh = {
        passwordAuthentication = false;
        allowSFTP = false; # Don't set this if you need sftp
        challengeResponseAuthentication = false;
        extraConfig = ''
            AllowTcpForwarding yes
            X11Forwarding no
            AllowAgentForwarding no
            AllowStreamLocalForwarding no
            AuthenticationMethods publickey
        '';
    };

    users.users.root.initialPassword = "hunter2";
    users.users.root.openssh.authorizedKeys.keys = [ (fetchKeys "asynthe") ]; # TESTING - LOL
    #users.users.root.openssh.authorizedKeys.keys = [ # SECRET
        #"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIY8tUQ59AvWkt0pTSMz2bf3O7emcO37IaA8vZCnXisk bendunstan@protonmail.com"
    #];

    # PERSISTENCE
    environment = {
        persistence."/nix/persist" = {
            directories = [
                "/etc/nixos" # nixos system config files, can be considered optional
                "/srv"       # service data
                "/var/lib"   # system service persistent data
                "/var/log"   # the place that journald dumps it logs to
            ];
        };
	etc = {
	    "machine-id".source = "/nix/persist/etc/machine-id"; # Important to read logs or for services that require it.
            "ssh/ssh_host_rsa_key".source = "/nix/persist/etc/ssh/ssh_host_rsa_key";
            "ssh/ssh_host_rsa_key.pub".source = "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
            "ssh/ssh_host_ed25519_key".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
            "ssh/ssh_host_ed25519_key.pub".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";
	};
    };

    # SECURITY
    # AUDIT TRACING
    security.auditd.enable = true;
    security.audit.enable = true;
    security.audit.rules = [
        "-a exit,always -F arch=b64 -S execve"
    ];
    # SUDO
    #security.sudo.enable = false;
    #security.sudo.execWheelOnly = true;
    #environment.defaultPackages = lib.mkForce [ clamav ]; # No default packages.
}
