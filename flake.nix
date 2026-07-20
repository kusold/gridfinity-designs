{
  description = "OpenSCAD dev environment for gridfinity-rebuilt-openscad";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # The gridfinity-rebuilt-openscad repo ships only .scad files (no flake.nix),
    # so we treat it as a plain source tree (`flake = false`) and expose its path
    # to OpenSCAD via OPENSCADPATH below.
    gridfinity-rebuilt-openscad = {
      url = "github:kennetek/gridfinity-rebuilt-openscad";
      flake = false;
    };
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem = { pkgs, ... }:
        let
          # The gridfinity-rebuilt-openscad library uses modern OpenSCAD syntax
          # (functions returning values, etc.) that the stable `openscad`
          # (2021.01) cannot parse, so we default to the dev snapshot. It also
          # gives the dramatic render speedups the upstream README mentions.
          openscad' = pkgs.openscad-unstable;

          lib = inputs.gridfinity-rebuilt-openscad;
        in
        {
          devShells.default = pkgs.mkShell {
            packages = [ openscad' pkgs.python3 ];

            # OPENSCADPATH makes `use <gridfinity-rebuilt-bins.scad>` (and the
            # library's internal `include <src/core/...>`) resolve from any of
            # your own .scad files without copying anything.
            shellHook = ''
              export OPENSCADPATH="${lib}"
              export GRIDFINITY_REBUILT_OPENSCAD="${lib}"
              echo "gridfinity devshell: OpenSCAD $(openscad --version 2>&1 | head -1)"
              echo "  OPENSCADPATH=$OPENSCADPATH"
            '';
          };
        };
    };
}
