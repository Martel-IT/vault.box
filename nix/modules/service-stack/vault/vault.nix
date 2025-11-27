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

    systemd.services.vault-setup = {
      description = "Vault Setup: Certs & Tailscale Domain Auto-detection";
      requiredBy = [ "vault.service" ];
      before = [ "vault.service" ];
      wants = [ "tailscaled.service" "network-online.target" ];
      after = [ "tailscaled.service" "network-online.target" ];
      
      path = with pkgs; [ tailscale jq coreutils openssl ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # vars
        DATA_DIR="/var/lib/vault-storage"
        CERT_DIR="$DATA_DIR/certs"
        ENV_FILE="$DATA_DIR/vault.env"
        KEY_FILE="$CERT_DIR/vault.key"
        CERT_FILE="$CERT_DIR/vault.crt"

        echo "--- [Vault Setup] Starting ---"
        mkdir -p "$CERT_DIR"
        chown -R vault:vault "$DATA_DIR"
        chmod 700 "$DATA_DIR"

        # A. WAIT TAILSCALE (Max 30s)
        echo "Waiting for Tailscale..."
        TIMEOUT=30
        TS_DOMAIN=""
        while [ $TIMEOUT -gt 0 ]; do
          STATUS=$(tailscale status --json 2>/dev/null)
          STATE=$(echo "$STATUS" | jq -r .BackendState)
          if [ "$STATE" == "Running" ]; then
            # Get clean domain
            TS_DOMAIN=$(echo "$STATUS" | jq -r .Self.DNSName | sed 's/\.$//')
            break
          fi
          sleep 2
          let TIMEOUT-=2
        done

        if [ -z "$TS_DOMAIN" ]; then
          echo "WARNING: Tailscale not running or offline. Fallback on localhost."
          TS_DOMAIN="localhost"
        fi

        echo "Detected Domain: $TS_DOMAIN"

        # B. GENERAZIONE FILE AMBIENTE (Per api_addr dinamico)
        # Vault userà queste variabili al posto di api_addr nel file di config
        echo "VAULT_API_ADDR=https://$TS_DOMAIN:8200" > "$ENV_FILE"
        echo "VAULT_CLUSTER_ADDR=https://$TS_DOMAIN:8201" >> "$ENV_FILE"
        # (Opzionale) Se vuoi forzare l'UI address
        echo "VAULT_UI=true" >> "$ENV_FILE" 

        # C. GESTIONE CERTIFICATI (Richiede cert a Tailscale o Self-Signed)
        # Se siamo su Tailscale valido, usiamo 'tailscale cert'
        if [[ "$TS_DOMAIN" == *".ts.net" ]]; then
            echo "Requesting Tailscale Certs..."
            tailscale cert --cert-file "$CERT_FILE" --key-file "$KEY_FILE" "$TS_DOMAIN"
        else
            # Fallback Self-Signed se non siamo su Tailscale
            if [ ! -f "$KEY_FILE" ]; then
              echo "Generating Self-Signed Certs..."
              openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
                -subj "/CN=$TS_DOMAIN" -keyout "$KEY_FILE" -out "$CERT_FILE"
            fi
        fi

        # Fix Permessi finali
        chown vault:vault "$KEY_FILE" "$CERT_FILE" "$ENV_FILE"
        chmod 600 "$KEY_FILE" "$ENV_FILE"
        chmod 644 "$CERT_FILE"
        
        echo "--- [Vault Setup] Complete. API Addr will be: https://$TS_DOMAIN:8200 ---"
      '';
    };

    # -----------------------------------------------------------
    # 2. OVERRIDE DEL SERVIZIO VAULT ESISTENTE
    # -----------------------------------------------------------
    systemd.services.vault = {
      # Carica le variabili generate dallo script sopra PRIMA di avviare Vault
      serviceConfig.EnvironmentFile = "/var/lib/vault-storage/vault.env";
      
      # Rimuoviamo il preStart precedente se lo avevi messo, ora fa tutto vault-setup
      preStart = lib.mkForce ""; 
    };


    systemd.tmpfiles.rules = [ 
      "d ${cfg.storagePath} 0700 vault vault - -"
      "d /var/lib/vault-storage/certs 0700 vault vault - -"
    ];

    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port cfg.clusterPort ];
  };
}