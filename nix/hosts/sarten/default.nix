{ config, ... }:
{
    flake.modules.nixos.host-sarten = { ... }: {
        imports = with config.flake.modules.nixos; [
            profile-server
            sarten-hardware sarten-filesystems

            # ─────────────── System ───────────────
            boot-bios gpg

            # ─────────────── AI ───────────────
            hermes

            # ─────────────── Media ───────────────
            jellyfin
            arr qbittorrent

            # ─────────────── Monitoring ───────────────
            prometheus grafana homepage
            docker wazuh wazuh-syslog

            # ─────────────── Virtualisation ───────────────
            incus
        ];

        # ─────────────── Identity ───────────────
        system.nixos.label = "sarten";
        system.name = "sarten";
        networking.hostName = "sarten";
        system.stateVersion = "26.05";
        time.timeZone = "America/Santiago";

        sys.sops.rootPassword = true;

        # ─────────────── Network ───────────────
        networking.useDHCP = false;
        networking.interfaces.eno1.ipv4.addresses = [
            { address = "192.168.1.135"; prefixLength = 24; }
        ];
        networking.defaultGateway = "192.168.1.1";
        networking.nameservers = [ "192.168.1.1" "1.1.1.1" ];

        # ─────────────── Deploy ───────────────
        sys.deploy.hostname = "192.168.1.135";
        sys.deploy.sshUser  = "asynthe";

        # ─────────────── Services ───────────────
        sys.hermes.dashboard   = true;
        sys.hermes.bind        = "sarten";
        sys.hermes.waitForHost = true;

        sys.jellyfin.mediaDir = "/srv/media";

        sys.grafana.bind     = "0.0.0.0";
        sys.prometheus.bind  = "0.0.0.0";
        sys.arr.bind         = "0.0.0.0";
        sys.qbittorrent.bind = "0.0.0.0";

        sys.homepage.host = "sarten";

        sys.homepage.backgrounds = [
            ../../../assets/backgrounds/anime_frieren_field.jpg
            ../../../assets/backgrounds/anime_your_name_comet.jpg
            ../../../assets/backgrounds/anime_window_city_bw.jpg
            ../../../assets/backgrounds/abstract_eva01_teal.jpg
        ];

        sys.arr.directorNames = {
            "wong-kar-wai" = "Wong Kar-wai";
        };

        # ─────────────── Incus ───────────────
        virtualisation.incus.ui.enable = true;
        virtualisation.incus.preseed = {
            config."core.https_address" = "0.0.0.0:8443";

            storage_pools = [{
                name   = "default";
                driver = "zfs";
                config.source = "tank/incus";
            }];

            networks = [
                {
                    name = "incusbr0";
                    type = "bridge";
                    config = {
                        "ipv4.address" = "auto";
                        "ipv6.address" = "none";
                    };
                }

                {
                    name = "labbr0";
                    type = "bridge";
                    config = {
                        "ipv4.address" = "10.66.66.1/24";
                        "ipv4.nat"     = "false";
                        "ipv4.dhcp"    = "true";
                        "ipv6.address" = "none";
                    };
                }
            ];

            profiles = [
                {
                    name = "default";
                    devices = {
                        root = { path = "/"; pool = "default"; type = "disk"; };
                        eth0 = { name = "eth0"; network = "incusbr0"; type = "nic"; };
                    };
                }

                {
                    name = "lab";
                    devices = {
                        root = { path = "/"; pool = "default"; type = "disk"; };
                        eth0 = { name = "eth0"; network = "labbr0"; type = "nic"; };
                    };
                }
            ];
        };

        # ─────────────── Kernel ───────────────
        boot.supportedFilesystems = [ "ext4" "zfs" ];

        networking.hostId = "6d68b7e4";
    };
}
