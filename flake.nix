{
    description = "asynthe's machines -- dendritic";

    inputs = {
        # The release every host runs. Bumping it is this line plus
        # `nix flake update nixpkgs`; stateVersion stays where it was installed.
        nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

        # Opt-in per package as pkgs.unstable.<name>, see nix/nixos/base/unstable.nix.
        nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

        flake-parts.url = "github:hercules-ci/flake-parts";
        flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
        import-tree.url = "github:vic/import-tree";

        deploy-rs.url = "github:serokell/deploy-rs";
        deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

        sops-nix.url = "github:Mic92/sops-nix";

        disko.url = "github:nix-community/disko";
        disko.inputs.nixpkgs.follows = "nixpkgs";

        hermes-agent.url = "github:NousResearch/hermes-agent";
    };

    outputs = inputs:
        inputs.flake-parts.lib.mkFlake { inherit inputs; }
            (inputs.import-tree ./nix);
}
