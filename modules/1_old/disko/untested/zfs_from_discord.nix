{
  disko.devices = {
    disk.disk1 = {
      device = systemDisk;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = luksName;
              # Grub2 2.12rc1 doesn't support argon2id and sha512 with LUKS2, yet, still..
              extraFormatArgs = [ "--pbkdf pbkdf2" "--hash sha256" ];
              initrdUnlock = true;
              settings = {
                allowDiscards = true;
                keyFile = "/tmp/disk-1.key";
              };
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
          encryptedSwap = {
            size = "8G";
            content = {
              type = "swap";
              randomEncryption = true;
              resumeDevice = true;
            };
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";
        postCreateHook = "zfs snapshot rpool/local/root@blank";
        datasets = {
          "local/root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
          };
          "local/boot" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/boot";
          };
          "local/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };
          "solid/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
          };
        };
      };
    };
  };
}
