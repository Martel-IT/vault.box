{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.vaultbox.services.tailscale;
in
{
  options.vaultbox.services.tailscale = {
    enable = mkEnableOption "Tailscale Support";
  };

  config = mkIf cfg.enable {

    services.tailscale = {
      enable = true;
      
      # 1. AUTO-ENROLLMENT
      authKeyFile = "/var/lib/tailscale/ts-auth-key.pvt";

      # 2. PARAMETRI EXTRA
      # --ssh: Enables Tailscale SSH 
      # --hostname: Enforces hostname in Tailscale admin panel
      extraUpFlags = [ 
        "--ssh" 
        "--hostname=${config.networking.hostName}" 
        "--accept-dns=true"
      ];
    };

    networking.firewall.allowedUDPPorts = [ 41641 ];
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
    
    systemd.tmpfiles.rules = [ 
      "d /var/lib/tailscale 0700 root root -"
    ];

    # --- CLEANUP SERVICE ---
    # starts after tailscaled svc and destroys the auth key file after successful enrollment
    systemd.services.tailscale-auth-cleanup = {
      description = "Delete Tailscale auth key after successful enrollment";
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      
      path = [ pkgs.tailscale pkgs.jq ];
      
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };

      script = ''
        KEY_FILE="/var/lib/tailscale/ts-auth-key.pvt"

        if [ ! -f "$KEY_FILE" ]; then
          echo "No keys found, nothing to do."
          exit 0
        fi

        echo "Key is present. Checking Tailscaled status..."
        
        # Waits for Tailscale to be OK.
        TIMEOUT=20
        while [ $TIMEOUT -gt 0 ]; do
          STATUS=$(tailscale status --json 2>/dev/null)
          STATE=$(echo "$STATUS" | jq -r .BackendState)
          
          if [ "$STATE" == "Running" ]; then
            echo "Tailscale is Running! Nuking the Auth Key..."
            rm -f "$KEY_FILE"
            echo "Auth Key nuked."
            exit 0
          fi
          
          sleep 2
          let TIMEOUT-=2
        done

        echo "WARNING: Tailscale did not reach 'Running' state. Key NOT deleted to facilitate debugging."
        exit 1
      '';
    };
  };
}