{
    description = "Minimal nixOS flake";

    # Inputs
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
        impermanence.url = "github:nix-community/impermanence";
        sops-nix.url = "github:Mic92/sops-nix";

	# disko
        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };

	# nixos-generators
        nixos-generators = {
            url = "github:nix-community/nixos-generators";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    # Outputs
    outputs = inputs @ {
        self,
        nixpkgs,
        nixpkgs-stable,
        impermanence,
        sops-nix,
        disko,
        nixos-generators,
    }: {

        # System configurations
        nixosConfigurations = {

            # Anywhere
            anywhere = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit
                    inputs
                    ;
                    hostname = "testing";
            	device = "/dev/vda";
                };
                modules = [
                    ./hosts/anywhere
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
            };

            # Server
            server = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit
                    inputs
                    ;
                    hostname = "server";
                };
                modules = [
                    ./hosts/server
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
            };

            # Red Team
            redteam = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit
                    inputs
                    ;
                    hostname = "redteam";
            	device = "/dev/vda";
            	user = "red";
                };
                modules = [
                    ./hosts/redteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
            };

            # Blue Team
            blueteam = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { inherit
                    inputs
                    ;
                    hostname = "blueteam";
            	device = "/dev/vda";
            	user = "blue";
                };
                modules = [
                    ./hosts/blueteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
            };
        };

        # Images
        packages.x86_64-linux = {

	    # Red Team - qcow2, vdi, ...
            redteam = nixos-generators.nixosGenerate {
                system = "x86_64-linux";
                format = "qcow-efi"; # ALL?
                specialArgs = { inherit
                    inputs
                    ;
                    hostname = "red";
                };
                modules = [
                    ./images/redteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
            };

	    # Blue Team - qcow2, vdi, ...
            blueteam = nixos-generators.nixosGenerate {
                system = "x86_64-linux";
                format = "vbox"; # ALL?
                specialArgs = { inherit
                    inputs
                    ;
                    hostname = "blue";
                };
                modules = [
                    ./images/blueteam
                    disko.nixosModules.disko
                    impermanence.nixosModules.impermanence
                ];
            };
        };
    };
}
