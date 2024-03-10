{ config, ... }: {

    imports = [

	# Disko
	../../modules/disko/ext4.nix

	../../modules/blueteam/boot.nix # Grub.
	../../modules/blueteam/console.nix # Bigger font console.
	../../modules/blueteam/pkgs.nix # Packages.
	../../modules/blueteam/system.nix # System configuration.
	../../modules/blueteam/user.nix # Users.

	# Desktop Environment
	../../modules/blueteam/desktop/xfce.nix
	#../../modules/blueteam/desktop/i3.nix # In progress.
	#../../modules/blueteam/desktop/xmonad.nix # In progress.

	# Monitoring
	#../../modules/blueteam/elasticsearch.nix
	#../../modules/blueteam/grafana.nix
	#../../modules/blueteam/loki.nix
	#../../modules/blueteam/prometheus.nix


	# Security Tool Box
	# https://fabaff.github.io/nix-security-box/

	# Chosen modules
        ../../modules/blueteam/security/cloud.nix
        ../../modules/blueteam/security/forensics.nix
        ../../modules/blueteam/security/information-gathering.nix
        ../../modules/blueteam/security/network.nix

        # modules
        #../../modules/blueteam/security/1_all.nix # Full package set.
        #../../modules/blueteam/security/bluetooth.nix
        #../../modules/blueteam/security/code.nix
        #../../modules/blueteam/security/container.nix
        #../../modules/blueteam/security/dns.nix
        #../../modules/blueteam/security/exploits.nix
        #../../modules/blueteam/security/fuzzers.nix
        #../../modules/blueteam/security/generic.nix
        #../../modules/blueteam/security/hardware.nix
        #../../modules/blueteam/security/host.nix
        #../../modules/blueteam/security/kubernetes.nix
        #../../modules/blueteam/security/ldap.nix
        #../../modules/blueteam/security/load-testing.nix
        #../../modules/blueteam/security/malware.nix
        #../../modules/blueteam/security/misc.nix
        #../../modules/blueteam/security/mobile.nix
        #../../modules/blueteam/security/packet-generators.nix
        #../../modules/blueteam/security/password.nix
        #../../modules/blueteam/security/port-scanners.nix
        #../../modules/blueteam/security/proxies.nix
        #../../modules/blueteam/security/services.nix
        #../../modules/blueteam/security/smartcards.nix
        #../../modules/blueteam/security/terminals.nix
        #../../modules/blueteam/security/tls.nix
        #../../modules/blueteam/security/traffic.nix
        #../../modules/blueteam/security/tunneling.nix
        #../../modules/blueteam/security/voip.nix
        #../../modules/blueteam/security/web.nix
        #../../modules/blueteam/security/windows.nix
        #../../modules/blueteam/security/wireless.nix

    ];
}
