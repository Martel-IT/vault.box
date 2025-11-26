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
    # Enable Flakes.
    nix = {
      package = pkgs.nixFlakes;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    # Install Emacs and make it the default editor system-wide.
    # Also install the given CLI tools and enable Bash completion.
    environment.systemPackages = [ pkgs.emacs-nox ] ++ tools;
    environment.variables = {
      EDITOR = "emacs";    # NOTE (1)
    };
    programs.bash.enableCompletion = true;

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