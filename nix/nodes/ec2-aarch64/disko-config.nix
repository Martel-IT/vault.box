{
  disko.devices = {
    disk = {
      
      # --- DISK 1: OS & BOOT (Root Volume) ---
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            #(UEFI)
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };

            
            #Root (OS)
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                extraArgs = [ "-L" "nixos" ]; 
              };
            };
          };
        };
      };

      # --- DISK 2: DATA VaultBox
      data = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            vaultbox_data = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted-data";
                settings.allowDiscards = true;
                passwordFile = "/tmp/disk-encryption.key";
                content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = null;
                extraArgs = [ "-L" "data" ];
                };
              };
            };
          };
        };
      };
  };
};
}