{ pkgs, lib, config, ... }: {

    # So that we can ssh into the VM, see e.g.
    # http://blog.patapon.info/nixos-local-vm/#accessing-the-vm-with-ssh
    services.openssh.enable = true;
    services.openssh.permitRootLogin = "yes";

    # Give root an empty password to ssh in.
    users.extraUsers.root.password = "";
    users.mutableUsers = false;
}
