{
    asynthe = {
        admin       = true;
        passwordKey = "users/meow";
        keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0H7gtdrNpsghM6LQ3jPDoeDkJMQW4/YDfc+DzMF1/j p1"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDnUPjUAi2Red+yEOocv3LorVYbA3VHTI6z4QjGX+9T s24"
        ];
    };

    kazu = {
        admin       = true;
        passwordKey = null;             # TODO add users/kazu to secrets.yaml, then name it here
        keys = [
            # TODO paste kazu's ssh-rsa public key
        ];
    };
}
