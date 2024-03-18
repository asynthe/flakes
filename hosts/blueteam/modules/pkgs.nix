{ pkgs, ... }: {

    environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
	    git
	    neovim
	    wget curl
	;
    };
}
