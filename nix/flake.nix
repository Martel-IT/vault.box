{
  description = "Vault.box - NixOS HashiCorp Vault Infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixie = {
      url = "github:c0c0n3/nixie";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixie, disko }:
  let

    inputPkgs =  nixpkgs;

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
      disko = disko;
      vaultbox = self; # Passes the flake itself
    };
  in

   { overlays.default = overlay; } // pkgs // modules // nodes;
}