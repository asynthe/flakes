{ config, ... }: {

    boot.kernel.sysctl = {
        "net.ipv4_forward=1";
    };
}
