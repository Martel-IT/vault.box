{ lib, ... }:

with lib;
with types;

{
  options.vaultbox.services.vault = {
    enable = mkEnableOption "HashiCorp Vault Service";

    dataDir = mkOption {
      type = path;
      default = "/var/lib/vault-storage";
      description = "Base directory for Vault data (mount point).";
    };

    storagePath = mkOption {
      type = path;
      default = "/var/lib/vault";
      description = "Directory for Raft storage.";
    };

    port = mkOption {
      type = port;
      default = 8200;
      description = "TCP port for Vaultbox API and UI";
    };

    clusterPort = mkOption {
      type = port;
      default = 8201;
      description = "Raft cluster communication port";
    };

    tls = {
      enable = mkEnableOption "TLS Listener";
      certFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to the TLS certificate file.";
      };
      keyFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to the TLS key file.";
      };
    };

    extraConfig = mkOption {
      type = lines;
      default = "";
      description = "Extra HCL configuration to append to Vault config.";
    };
  };
}