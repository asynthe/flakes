{ ... }:
{
    flake.modules.nixos.docs = { config, lib, pkgs, ... }: {
        options.sys.docs = {
            port = lib.mkOption {
                type        = lib.types.port;
                default     = 8081;
                description = "Port the rendered docs listen on";
            };

            title = lib.mkOption {
                type        = lib.types.str;
                default     = config.networking.hostName;
                description = "Book title, shown in the sidebar header and the tab";
            };

            src = lib.mkOption {
                type        = lib.types.path;
                default     = ../../../docs;
                description = "Directory holding book.toml, SUMMARY.md and the chapters";
            };

            openFirewall = lib.mkOption {
                type        = lib.types.bool;
                default     = false;
                description = "Put the docs on the LAN; the tailnet reaches them either way";
            };
        };

        config = let
            cfg = config.sys.docs;

            # mdBook writes into the source tree by default, so the build gets a
            # writable copy and an out-of-tree build-dir. `--dest-dir` is
            # resolved relative to book.toml, hence the absolute $out.
            book = pkgs.runCommand "${config.networking.hostName}-docs"
                { nativeBuildInputs = [ pkgs.mdbook ]; }
                ''
                    cp -r ${cfg.src} book && chmod -R u+w book
                    substituteInPlace book/book.toml \
                        --replace-fail '@title@' ${lib.escapeShellArg cfg.title}
                    mdbook build book --dest-dir "$out"
                    rm -f "$out/book.toml"
                '';
        in {
            services.nginx = {
                enable = true;

                # Its own vhost rather than a path on the dashboard's: the two
                # aspects stay independent, and the dashboard keeps `default`.
                virtualHosts."${config.networking.hostName}-docs" = {
                    listen = [ { addr = "0.0.0.0"; port = cfg.port; } ];
                    root   = book;
                    extraConfig = "error_page 404 /404.html;";
                };
            };

            networking.firewall.allowedTCPPorts =
                lib.mkIf cfg.openFirewall [ cfg.port ];
        };
    };
}
