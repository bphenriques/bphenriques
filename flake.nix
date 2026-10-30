{
  description = "bphenriques.com";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    dotfiles = { url = "github:bphenriques/dotfiles"; flake = false; };   # Only reads fleet.json, never evaluates the flake
  };

  outputs = { nixpkgs, dotfiles, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in {
      packages = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./package.nix {
          fleet = nixpkgs.lib.importJSON "${dotfiles}/fleet.json";
        };
      });
    };
}
