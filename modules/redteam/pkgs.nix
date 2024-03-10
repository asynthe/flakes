{ pkgs, ... }: {

    #environment.systemPackages = map lib.lowPrio [ pkgs.curl pkgs.gitMinimal ]; ?

    environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
	    curl
	    git
	;
    };
}
