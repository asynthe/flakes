# ... configuration.nix:
# { config, pkgs, hostname, modulesPath, ... }:
# {
# imports = [ (modulesPath + "/virtualisation/digital-ocean-config.nix") ];
# networking.hostName = hostname;
# ...
# }

{
  description = "Minimal nixOS flake";

inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
  impermanence.url = "github:nix-community/impermanence";
  sops-nix.url = "github:Mic92/sops-nix";
  disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

outputs = inputs @ {
    self,
    nixpkgs,
    disko,
    impermanence,
    sops-nix,
}:
{
nixosConfigurations = {

server = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit
    username
    hostname
    inputs
    ;
    hostname = "server"
  };
  modules = [
    ./hosts/linux/server
    disko.nixosModules.disko
    impermanence.nixosModules.impermanence
  ];
};

hyperv = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit
    inputs
    ;
  };
  modules = [
    ./hosts/hyperv
    disko.nixosModules.disko
    impermanence.nixosModules.impermanence
  ];
};

staging = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./configuration.nix ];
  # Example how to pass an arg to configuration.nix:
  specialArgs = { hostname = "staging"; };
};

};
  };
}
