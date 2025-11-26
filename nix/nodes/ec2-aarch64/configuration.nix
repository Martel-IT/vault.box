{ config, modulesPath, pkgs, lib, ... }:
let
  
  vault-data-mount-dir = "/var/lib/vault-storage";

in {

  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];

  time.timeZone = "Europe/Amsterdam";
  system.stateVersion = "25.05";

  networking.hostName = "vaultsrv-01";

  fileSystems."${vault-data-mount-dir}" = {
    device = "/dev/disk/by-partlabel/data";
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
      storagePath = "${vault-data-mount-dir}/raft-data";
      tls = {
        enable = true;
        certFile = "/var/lib/vault-storage/certs/vault.crt";
        keyFile  = "/var/lib/vault-storage/certs/vault.key";
      };
    };
    swapfile = {
      enable = true;
      size = 4096;
    };
  };
}