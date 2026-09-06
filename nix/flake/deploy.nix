# Every host that imports the `deploy` aspect becomes a deploy-rs node.
# The target address and ssh user are the host's own to state, so they live in
# `sys.deploy.*` rather than being repeated here.
{ config, lib, inputs, ... }:
let
    deployable = lib.filterAttrs
        (_: host: host.config.sys.deploy.enabled)
        config.flake.nixosConfigurations;

    mkNode = _: host: let
        cfg    = host.config.sys.deploy;
        system = host.config.nixpkgs.hostPlatform.system;
    in {
        inherit (cfg)
            hostname sshUser user sshOpts
            autoRollback magicRollback remoteBuild;

        profiles.system.path =
            inputs.deploy-rs.lib.${system}.activate.nixos host;
    };
in {
    flake.deploy.nodes = lib.mapAttrs mkNode deployable;
}
