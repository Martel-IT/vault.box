{
  description = "Vault.box - NixOS HashiCorp Vault Infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixie = {
      url = "github:c0c0n3/nixie";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixie }:
  let

    inputPkgs =  inherit nixpkgs;

    build = nixie.lib.flakes.mkOutputSetForCoreSystems inputPkgs;
    pkgs = build (import ./pkgs/mkSysOutput.nix);

    overlay = final: prev: {
      vaultbox = pkgs.packages.${prev.system} or {};
    };

    modules = {
      nixosModules.imports = [
        ./modules
      ];
    };

    nodes = import ./nodes {
      nixosSystem = nixpkgs.lib.nixosSystem;
      vaultbox = self; # Passes the flake itself
    };
  in

   { inherit overlay; } // pkgs // modules // nodes;
}