{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.vaultbox.services.vault;
in
{
  config = mkIf cfg.enable {
    
    services.vault = {
      enable = true;
      package = pkgs.vault-bin;

      # 1. ADDRESS
      address = "0.0.0.0:${toString cfg.port}";

      # 2. STORAGE

      storageBackend = "raft";      
      storagePath = cfg.storagePath;
      storageConfig = ''
        node_id = "${config.networking.hostName}"
      '';

      tlsCertFile = if cfg.tls.enable then cfg.tls.certFile else null;
      tlsKeyFile  = if cfg.tls.enable then cfg.tls.keyFile else null;

      # 4. EXTRA CONFIG (global)
      extraConfig = ''
        ui = true
        disable_mlock = true

        # Parametri per il cluster (non per il listener)
        api_addr = "http${if cfg.tls.enable then "s" else ""}://127.0.0.1:${toString cfg.port}"
        cluster_addr = "http${if cfg.tls.enable then "s" else ""}://127.0.0.1:${toString cfg.clusterPort}"

        ${cfg.extraConfig}
      '';
    };

    environment.systemPackages = [ pkgs.vault-bin ];

    systemd.tmpfiles.rules = [ 
      "d ${cfg.storagePath} 0700 vault vault - -"
      "d /var/lib/vault-storage/certs 0700 vault vault - -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port cfg.clusterPort ];
  };
}