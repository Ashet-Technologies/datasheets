{
  description = "Ashet Technologies Datasheet Collection";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  } @ inputs: let
    systems = ["x86_64-linux"];
  in
    flake-utils.lib.eachSystem systems (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in rec {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "ashet-datasheets";
          src = ./.;
          nativeBuildInputs = [
            pkgs.lua5_3_compat
            pkgs.pandoc
            pkgs.libreoffice
            pkgs.texliveFull
            pkgs.inkscape
          ];

          configurePhase = "";

          buildPhase = ''
            ./render.sh
          '';

          installPhase = ''
            mv output $out
          '';
        };
      }
    );
}
