{ config, pkgs, ... }: {

    users.users.root.initialHashedPassword = "";

    # install user `nixusr`
    users.users.nixusr = {
        isNormalUser = true;
        home = "/home/nixusr";
        description = "nixusr user";
        extraGroups = [ "wheel" ];
        uid = 1000;
        
	# `mkpasswd -m sha-512`
        hashedPassword = "$6$bIj/yHEKrsB4GIg9$SW2OHgWTvoC5AVlENwhWkBY7tF6SSG8z6cT/bSEuyw2Jy7U2qui1isCQjeDd.ti94FI..DyKExk/FCR0FpyEO/";
        
	#openssh.authorizedKeys.keys = [ # SECRET
            #"ssh-rsa x"
        #];
    };
};

