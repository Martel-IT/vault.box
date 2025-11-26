{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.vaultbox.services.vault;

  tlsString = if cfg.tls.enable then ''
    tls_disable = 0
    tls_cert_file = "${cfg.tls.certFile}"
    tls_key_file  = "${cfg.tls.keyFile}"
  '' else ''
    tls_disable = 1
  '';
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
        
        listener "tcp" {
          address     = "0.0.0.0:${toString cfg.port}"
          ${tlsString}
        }

        storage "raft" {
          path    = "${cfg.storagePath}"
          node_id = "${config.networking.hostName}"
        }

        api_addr = "http${if cfg.tls.enable then "s" else ""}://127.0.0.1:${toString cfg.port}"
        cluster_addr = "http${if cfg.tls.enable then "s" else ""}://127.0.0.1:${toString cfg.clusterPort}"

        # Qui iniettiamo eventuale config extra definita nel nodo
        ${cfg.extraConfig}
      '';
    };

    systemd.tmpfiles.rules = [ "d ${cfg.storagePath} 0700 vault vault - -" ];
    networking.firewall.allowedTCPPorts = [ cfg.port cfg.clusterPort ];
  };
}