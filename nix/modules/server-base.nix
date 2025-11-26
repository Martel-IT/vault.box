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

    # SSH Hardening (Break-glass access)
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
        PermitRootLogin = "no";
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
      { domain = "*"; type = "soft"; item = "nofile"; value = "65536"; }
      { domain = "*"; type = "hard"; item = "nofile"; value = "65536"; }
    ];

    # Service Stack: Vault + Tailscale
    vaultbox.services = {
      vault = {
        enable = true;
      };
      tailscale = {
        enable = true;
      };
    };
  });
}