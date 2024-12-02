{
  stdenvNoCC,
  mkWest2nixHook,
  python3,
  gitMinimal,
}:
{
  west2nixToml,
}:
let
  west2nixHook = mkWest2nixHook {
    manifest = west2nixToml;
  };
in
stdenvNoCC.mkDerivation {
  name = "west-dependencies";
  unpackPhase = "true";
  nativeBuildInputs = [
    west2nixHook
    python3.pkgs.west
    gitMinimal
  ];
  env = {
    dontUseWestConfigure = 1;
    dontUseWestBuild = 1;
  };
  dontFixup = true;
  installPhase = ''
    mkdir -p $out
    cp -r {.,}* $out
  '';
}
