{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.vaultbox.services.vault;
in
{
  config = mkIf cfg.enable {
    
    services.vault = {
      enable = true;
      package = pkgs.vault;
      
      # API address
      address = "0.0.0.0:${toString cfg.port}";

      # HCL Config.
      extraConfig = ''
        ui = true
        
        # Listener TCP standard
        listener "tcp" {
          address     = "0.0.0.0:${toString cfg.port}"
          tls_disable = 1  # TODO: Abilitare TLS in produzione!
        }

        # Storage Backend: Integrated Raft
        storage "raft" {
          path    = "${cfg.storagePath}"
          node_id = "${config.networking.hostName}"
        }

        api_addr = "http://127.0.0.1:${toString cfg.port}"
        cluster_addr = "http://127.0.0.1:${toString cfg.clusterPort}"
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.storagePath} 0700 vault vault - -"
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port cfg.clusterPort ];
  };
}