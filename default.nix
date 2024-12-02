{ callPackage, python3 }:
rec {
  west2nix = python3.pkgs.callPackage ./package.nix { };
  mkWest2nixHook = callPackage ./hook.nix { };
  mkWestDependencies = callPackage ./make-west-dependencies.nix {
    inherit mkWest2nixHook;
  };
}
