# The only options declared outside an aspect: values that genuinely differ
# between machines, plus the deploy target every host has to state for itself.
{ ... }:
{
    flake.modules.nixos.core = { config, lib, ... }: {
        options.sys = {
            flake = lib.mkOption {
                type        = lib.types.str;
                default     = "/home/meow/flakes";
                description = "Path to this flake, used by nh";
            };

            deploy = {
                # Set by the `deploy` aspect. A host that never imported it is
                # skipped by nix/flake/deploy.nix instead of failing to evaluate.
                enabled = lib.mkOption {
                    type        = lib.types.bool;
                    default     = false;
                    internal    = true;
                    description = "Whether this host is a deploy-rs node";
                };

                hostname = lib.mkOption {
                    type        = lib.types.str;
                    default     = config.networking.hostName;
                    description = "Address deploy-rs connects to; the tailnet name resolves everywhere";
                };

                sshUser = lib.mkOption {
                    type        = lib.types.str;
                    default     = lib.head config.sys.admins;
                    description = "Account deploy-rs ssh's in as; its key must be in auth.nix";
                };

                user = lib.mkOption {
                    type        = lib.types.str;
                    default     = "root";
                    description = "Account the activation runs as, reached from sshUser by sudo";
                };

                sshOpts = lib.mkOption {
                    type        = lib.types.listOf lib.types.str;
                    default     = [];
                    example     = [ "-p" "2222" ];
                    description = "Extra ssh arguments";
                };

                remoteBuild = lib.mkOption {
                    type        = lib.types.bool;
                    default     = false;
                    description = ''
                        Build on the target instead of pushing a closure. Off by
                        default: the workstation is almost always the faster box.
                    '';
                };

                autoRollback = lib.mkOption {
                    type        = lib.types.bool;
                    default     = true;
                    description = "Roll back if activation itself fails";
                };

                magicRollback = lib.mkOption {
                    type        = lib.types.bool;
                    default     = true;
                    description = ''
                        Roll back if the deployer cannot reach the machine after
                        activation. This is what saves a box from a bad firewall
                        or network change; turn it off only for a host you can
                        physically reach.
                    '';
                };
            };
        };
    };
}
