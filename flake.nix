{
  description = "Build Zephyr West-managed projects with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    zephyr-nix.url = "github:wrvsrx/zephyr-nix";
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs: (
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    rec {
      lib.mkWest2nix = { pkgs }: pkgs.callPackage ./. { };

      overlays.default = final: prev: lib.mkWest2nix { pkgs = prev; };

      packages =
        forAllSystems
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            {
              default = (pkgs.callPackage ./. { }).west2nix;
            }
          );

      checks =
        forAllSystems
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
              callPackage = pkgs.newScope (pkgs // {
                zephyr = inputs.zephyr-nix.packages.${system};
                west2nix = callPackage ./. { };
              });
            in
            {
              project = callPackage ./templates/application { };
              package = self.packages.${system}.default;
            }
          );
    }
  );
}
