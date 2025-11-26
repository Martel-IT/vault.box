{ lib, ... }:

with lib;
with types;

{
  options.vaultbox.services.vault = {
    enable = mkEnableOption "HashiCorp Vault Service";

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
  };
}