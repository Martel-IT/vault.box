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
    inherit system;
    modules = [
      vaultbox.nixosModules
      config
    ];
  };
in {
  nixosConfigurations = {
    aarch64-linux = mkNode "aarch64-linux" ./ec2-aarch64/configuration.nix;
    devm = mkNode "aarch64-linux" ./devm/configuration.nix;
  };
}