{ config, lib, ... }:

with lib;
let
  cfg = config.vaultbox.services.vault;
in
{
  config = mkIf cfg.enable {
    
    systemd.services.vault.serviceConfig = {
      # File system isolation
      # We using mkForce to override defaults set by NixOS service module (read-only).
      ProtectSystem = mkForce "strict";     # File system read only
      ProtectHome = mkForce true;           # No /home access
      PrivateTmp = true;            # /tmp isolated
      PrivateDevices = true;        # No access to physical devices
      
      # Allow WRITE permissions only where needed (Raft storage)
      ReadWritePaths = [ cfg.storagePath ];

      # Kernel/Processes isolation
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ]; # Solo rete
      RestrictNamespaces = true;
      
      # Prevent privilege escalation
      NoNewPrivileges = true;
      
      # Remove almost all linux capabilities, keep only those needed
      CapabilityBoundingSet = [ "CAP_IPC_LOCK" "CAP_SYSLOG" ]; # IPC_LOCK is needed due to mlock (prevent memory swapping)
      AmbientCapabilities = [ "CAP_IPC_LOCK" ];
    };
  };
}