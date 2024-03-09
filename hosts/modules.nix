{ config, ... }: {

    imports = [

        # Boot
	../modules/boot/grub_anywhere.nix # Grub for nixos-anywhere.

        # Disk configurations
        ../modules/disko/impermanence/btrfs_config.nix
        ../modules/disko/impermanence/btrfs_module.nix
	#../modules/disko/ext4_lvm.nix

	# Databases
	#../modules/db/postgresql.nix

	# System
	../modules/system/console.nix
	../modules/system/pkgs.nix
	../modules/system/usr.nix

	# Monitoring
	#../modules/monitoring/elasticsearch.nix
	#../modules/monitoring/grafana.nix
	#../modules/monitoring/loki.nix
	#../modules/monitoring/prometheus.nix

	# Security
	#../modules/security/security-tool-box.nix

    ];
}
