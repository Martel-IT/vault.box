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

    services.tailscale.enable = true;

    networking.firewall.allowedUDPPorts = [ 41641 ];
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}