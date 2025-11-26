{ config, lib, pkgs, ... }:

with lib;
with types;

{

  options = {
    vaultbox.base.enable = mkOption {
      type = bool;
      default = false;
      description = ''
        Enable it to install this system base.
      '';
    };
    vaultbox.base.cli-tools = mkOption {
      type = listOf package;
      default = [];
      description = ''
        CLI tools to install system-wide.
      '';
    };
  };

  config = let
    enabled = config.vaultbox.base.enable;
    tools = config.vaultbox.base.cli-tools;
  in (lib.mkIf enabled
  {

    nixpkgs.config.allowUnfree = true; # NOTE (1)  
    # Enable Flakes.
    nix = {
      package = pkgs.nix;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    # Install Emacs and make it the default editor system-wide.
    # Also install the given CLI tools and enable Bash completion.
    environment.systemPackages = [ pkgs.emacs-nox pkgs.vault-bin pkgs.vault ] ++ tools;
    environment.variables = {
      EDITOR = "emacs";    # NOTE (1)
    };
    programs.bash.completion.enable = true;

    # Only allow to change users and groups through NixOS config.
    users.mutableUsers = false;

    users.users.admin = {
      isNormalUser = true;
      description = "System Administrator";
      extraGroups = [ "wheel" "systemd-journal" ]; # 'wheel' per sudo
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsM1MtOMasHl9p6MJ9ABvHThoaYzLCJlP5VjyA81f9/"
      ];
    };

    # Let wheel users run `sudo` without a password.
    security.sudo.wheelNeedsPassword = false;

  });
}

# NOTE
# ----
# 1. Vault changed its licence to BSL (Business Source License) so to avoid 
# error: Package ‘vault-1.20.4’ in /nix/store/g02rq8ap30x3fp8zrz07ip5v1s0pzidn-source/pkgs/by-name/va/vault/package.nix:76 has an unfree license (‘bsl11’), refusing to evaluate.
# we need to declare allowUnfree = true;