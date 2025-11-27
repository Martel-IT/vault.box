{ config, modulesPath, pkgs, lib, ... }:
let
  
  cfg = config.vaultbox.services.vault;

in {

  imports = [ 
    "${modulesPath}/virtualisation/amazon-image.nix" 
    ./disko-config.nix
  ];

  ec2.efi = true;

  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "25.05";

  networking.hostName = "vaultsrv-01";

  fileSystems."${cfg.dataDir}" = {
    device = "/dev/disk/by-label/data";
    fsType = "ext4";
    options = [ "defaults" "noatime" ]; 
  };

  # Automatic security updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;  # Don't auto-reboot production
    dates = "04:00";
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
  };

  services.openssh.settings = {
    PermitRootLogin = lib.mkForce "no";
    PasswordAuthentication = lib.mkForce false;
  };


  vaultbox = {
    server.enable = true;
    services.vault = {
      storagePath = "${cfg.dataDir}/raft-data";
      tls = {
        enable = true;
        certFile = "${cfg.dataDir}/certs/vault.crt";
        keyFile  = "${cfg.dataDir}/certs/vault.key";
      };
    };
    swapfile = {
      enable = true;
      size = 4096;
    };
  };
}