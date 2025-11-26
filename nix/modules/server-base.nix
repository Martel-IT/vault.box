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

let
  cfg = config.vaultbox.services.vault;
in

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
    # SSH hardening
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
        PermitRootLogin = lib.mkForce "no";
        X11Forwarding = false;
        MaxAuthTries = 3;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };
      extraConfig = ''
        AllowUsers admin
        Protocol 2
        LoginGraceTime 30
        MaxSessions 10
        MaxStartups 10:30:60
      '';
    };

    # Security limits
    security.pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "65536";
      }
    ];

    # Bring in our Vault service stack.
    vaultbox.services.vault = {
      enable = true;
    };
  });

}