{ pkgs, ... }: {

    environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
	    tmux
	    neovim
	    git
	;
    };
}
