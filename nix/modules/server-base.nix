#
# Base Vaultbox server machine.
#
# This module brings together several other modules to
# - build our base OS (`vaultbox`);
# - enable SSH;
# - only open the ports we actually need;
# - run the vault service stack (`vault.service-stack`),
#   including PgAdmin.
#
# Each machine we build (dev VM, staging, prod) enables this module
# to bring in the bulk of the required functionality and then bolts
# on machine-specific tweaks like passwords, time zone, swap file,
# and so on.
#
{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    vaultbox.server.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install the base Vault server machine.
      '';
    };
  };

  config = let
    enabled = config.vaultbox.server.enable;
  in (mkIf enabled
  {
    # Start from our OS base config.
    vaultbox.base = {
      enable = true;
      cli-tools = pkgs.vaultbox.linux-admin-shell.paths;
    };

    # Allow remote access through SSH.
    services.openssh = {
      enable = true;
    };

    # Set up a firewall to let in only SSH and HTTP traffic.
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ ];
    };

    # Bring in our Vault service stack.
    vaultbox.service-stack = {
      enable = true;
      vault-db-name = "Vault_martel_14";
    };
  });

}