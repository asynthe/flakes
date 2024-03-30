{ config, ... }: {

    imports = [

	# Disko
        #./modules/disko/ext4.nix
        ./modules/disko/btrfs_impermanence.nix

	# List of packages (besides Security Toolbox)
	./modules/pkgs.nix # Packages.

	# System modules
	./modules/system/console.nix # Bigger font console.
	./modules/system/system.nix # System configuration.
	./modules/system/user.nix # Users.

	# Desktop Environment
	../../modules/desktop/xfce.nix # XFCE
	#../../modules/desktop/i3.nix # In progress.

	# Security
	../../modules/security/clamav.nix # Antivirus.

	# Monitoring
	#./modules/monitoring/elasticsearch.nix
	#./modules/monitoring/grafana.nix
	#./modules/monitoring/loki.nix
	#./modules/monitoring/prometheus.nix

	# systemd services
	../../modules/systemd/xfce_random_wallpaper.nix
	../../modules/systemd/xfce_screen_always_on.nix

        # -------------------------------------------------
	# Security Tool Box
	# https://fabaff.github.io/nix-security-box/

	# Chosen from list

        #./modules/security/cloud.nix
        #./modules/security/forensics.nix
        #./modules/security/information-gathering.nix
        #./modules/security/network.nix

        # All Modules

        #./modules/security/1_all.nix # Full package set.
        #./modules/security/bluetooth.nix
        #./modules/security/code.nix
        #./modules/security/container.nix
        #./modules/security/dns.nix
        #./modules/security/exploits.nix
        #./modules/security/fuzzers.nix
        #./modules/security/generic.nix
        #./modules/security/hardware.nix
        #./modules/security/host.nix
        #./modules/security/kubernetes.nix
        #./modules/security/ldap.nix
        #./modules/security/load-testing.nix
        #./modules/security/malware.nix
        #./modules/security/misc.nix
        #./modules/security/mobile.nix
        #./modules/security/packet-generators.nix
        #./modules/security/password.nix
        #./modules/security/port-scanners.nix
        #./modules/security/proxies.nix
        #./modules/security/services.nix
        #./modules/security/smartcards.nix
        #./modules/security/terminals.nix
        #./modules/security/tls.nix
        #./modules/security/traffic.nix
        #./modules/security/tunneling.nix
        #./modules/security/voip.nix
        #./modules/security/web.nix
        #./modules/security/windows.nix
        #./modules/security/wireless.nix
        # -------------------------------------------------
    ];
}
