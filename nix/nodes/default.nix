#
# Function to generate the NixOS configurations for the Flake output.
#
{
  # `lib.nixosSystem` in the selected Nixpkgs.
  nixosSystem,
  # The Flake itself.
  vaultbox
}:
let
  mkNode = system: config: nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = system; }
      ({ config, pkgs, ... }: { nixpkgs.overlays = [ vaultbox.overlays.default ]; })
      vaultbox.nixosModules
      config
    ];
  };
in {
  nixosConfigurations = {
    aarch64-linux = mkNode "aarch64-linux" ./ec2-aarch64/configuration.nix;
    x86_64-linux = mkNode "x86_64-linux" ./ec2-x86_64/configuration.nix;
    devm = mkNode "aarch64-linux" ./devm/configuration.nix;
  };
}