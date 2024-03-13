{ config, pkgs, ... }: {

    environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
	    neovim
	    tmux
	    ;
    };
}
