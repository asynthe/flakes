{ ... }:
{
    flake.modules.nixos.ollama = { config, lib, pkgs, ... }: {
        options.sys.ollama = {
            cuda = lib.mkEnableOption "CUDA-accelerated Ollama, which needs an NVIDIA GPU aspect";
            models = lib.mkOption {
                type        = lib.types.listOf lib.types.str;
                default     = [];
                description = "Models to preload on startup";
            };
        };

        config.services.ollama = {
            enable     = true;
            package    = if config.sys.ollama.cuda then pkgs.ollama-cuda else pkgs.ollama;
            syncModels = true;
            loadModels = config.sys.ollama.models;
        };
    };

    flake.modules.nixos.fabric = { pkgs, ... }: {
        environment.systemPackages = [ pkgs.fabric-ai ];
    };

    flake.modules.nixos.openclaw = { pkgs, ... }: {
        environment.systemPackages = [ pkgs.openclaw ];
    };
}
