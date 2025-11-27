{ config, modulesPath, pkgs, lib, ... }:
let
  
  cfg = config.vaultbox.services.vault;

in {

  imports = [ ./hardware-configuration.nix ];

  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "25.05";

  networking.hostName = "vaultsrv-01";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  users.users.root.password = "abc123"; # Password: "root" -- DO NOT USE THIS IN PRODUCTION SYSTEMS!!!!!!!!!!
  users.mutableUsers = lib.mkForce true; # Allows to use passwd to change passwords

  services.openssh.settings = {
    PermitRootLogin = lib.mkForce "yes";
    PasswordAuthentication = lib.mkForce true;
  };

  services.openssh.extraConfig = lib.mkForce ''
    AllowUsers admin root
    Protocol 2
  '';


  vaultbox = {
    server.enable = true;
    services.vault = {
      storagePath = "${cfg.dataDir}/raft-data";
      # tls = {
      #   enable = true;
      #   certFile = "/var/lib/vault-storage/certs/vault.crt";
      #   keyFile  = "/var/lib/vault-storage/certs/vault.key";
      # };
    };
    swapfile = {
      enable = true;
      size = 4096;
    };
  };
}