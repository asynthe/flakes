# Who may log in to these machines, and with which key.
#
# Data, not a module: it sits outside nix/ so import-tree never picks it up, and
# `nix/nixos/base/auth.nix` is what turns it into accounts. Every machine that
# imports the `auth` aspect gets every user here.
#
#   admin        wheel (sudo) and a nix daemon trusted-user
#   keys         ssh public keys; an account with none cannot log in at all
#   passwordKey  where the login hash lives in secrets/secrets.yaml, or null for
#                a locked password -- key-only ssh, and sudo will not work
#
# Adding a password:
#
#   mkpasswd -m yescrypt          # on any machine, paste the hash below
#   sops secrets/secrets.yaml     # add it under `users:` as <name>: <hash>
#
# The hash is `neededForUsers`, so a passwordKey naming an entry that does not
# exist fails the whole activation, not just that account.
{
    asynthe = {
        admin = true;

        # The hash already in secrets.yaml, from when this account was `meow`.
        # Rename that sops key to users/asynthe and drop this line when convenient.
        passwordKey = "users/meow";

        keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0H7gtdrNpsghM6LQ3jPDoeDkJMQW4/YDfc+DzMF1/j p1"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDnUPjUAi2Red+yEOocv3LorVYbA3VHTI6z4QjGX+9T s24"
        ];
    };

    # Reaches the box over tailscale.
    kazu = {
        admin = true;

        # TODO -- null means kazu cannot sudo. Add `users/kazu` to
        # secrets/secrets.yaml as above, then set this to "users/kazu".
        passwordKey = null;

        # TODO -- paste the ssh-rsa public key. While this list is empty kazu
        # cannot log in at all. RSA is fine: any current client signs with
        # rsa-sha2-256/512, which openssh still accepts.
        keys = [ ];
    };
}
