# No nixpkgs package, so upstream's compose file is used as published and NixOS owns
# only the kernel tuning, the state directory and the unit. Certs are a manual step.
{ ... }:
{
    flake.modules.nixos.wazuh = { config, lib, pkgs, ... }: {
        options.sys.wazuh = {
            dataDir = lib.mkOption {
                type        = lib.types.str;
                default     = "/srv/wazuh";
                description = "Holds the compose checkout, certs and volumes; put it on the pool";
            };

            dashboardPort = lib.mkOption {
                type        = lib.types.port;
                default     = 443;
                description = "Host port the dashboard is published on; 8443 is incus";
            };

            openFirewall = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Open the dashboard and agent ports to the LAN";
            };
        };

        config = let cfg = config.sys.wazuh; in {
            # The indexer is OpenSearch and refuses to start under this.
            boot.kernel.sysctl."vm.max_map_count" = 262144;

            systemd.tmpfiles.rules = [ "d ${cfg.dataDir} 0750 root root - -" ];

            systemd.services.wazuh = {
                description = "Wazuh single-node stack";
                after       = [ "docker.service" "network-online.target" ];
                requires    = [ "docker.service" ];
                wants       = [ "network-online.target" ];
                wantedBy    = [ "multi-user.target" ];

                # Skipped, not failed, until the checkout exists.
                unitConfig.ConditionPathExists =
                    "${cfg.dataDir}/single-node/docker-compose.yml";

                serviceConfig = {
                    Type             = "oneshot";
                    RemainAfterExit  = true;
                    WorkingDirectory = "${cfg.dataDir}/single-node";
                    # First run pulls several GB of images.
                    TimeoutStartSec  = "1800";
                    ExecStart        = "${pkgs.docker-compose}/bin/docker-compose up -d";
                    ExecStop         = "${pkgs.docker-compose}/bin/docker-compose down";
                };
            };

            # 1514/1515 are agent enrolment and reporting, 55000 the manager API.
            networking.firewall.allowedTCPPorts =
                lib.mkIf cfg.openFirewall [ cfg.dashboardPort 1514 1515 55000 ];
        };
    };

    # Ships a host's journal to the manager's syslog listener. There is no
    # wazuh-agent in nixpkgs, so this is what reporting in looks like here.
    flake.modules.nixos.wazuh-syslog = { config, lib, ... }: {
        options.sys.wazuh = {
            syslogTarget = lib.mkOption {
                type        = lib.types.str;
                default     = "sarten";
                description = "Host running the manager's syslog listener";
            };

            syslogPort = lib.mkOption {
                type        = lib.types.port;
                default     = 514;
                description = "UDP port the manager accepts syslog on";
            };
        };

        config = let cfg = config.sys.wazuh; in {
            services.rsyslogd = {
                enable = true;

                # journald stays the log store; this instance only forwards.
                defaultConfig = "";

                # UDP because that is the only 514 the compose file publishes.
                extraConfig = ''
                    module(load="imjournal" StateFile="imjournal.state")

                    *.* action(type="omfwd"
                               target="${cfg.syslogTarget}"
                               port="${toString cfg.syslogPort}"
                               protocol="udp"
                               template="RSYSLOG_SyslogProtocol23Format")
                '';
            };
        };
    };
}
