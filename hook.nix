{
  lib,
  makeSetupHook,
  gitMinimal,
  fetchgit,
  stdenvNoCC,
  python3,
}:
{
  manifest,
}:
let
  manifest' =
    if builtins.isPath manifest || builtins.hasContext manifest then
      (lib.importTOML manifest)
    else
      manifest;
  srcToFakeGit =
    { name, src }:
    stdenvNoCC.mkDerivation {
      name = "${name}-fakegit";
      inherit src;
      dontFixup = true;
      nativeBuildInputs = [ gitMinimal ];
      buildPhase = ''
        echo Creating fake dummy git repo

        git init
        git config user.email 'foo@example.com'
        git config user.name 'Foo Bar'
        git add -A
        git commit -m 'Fake commit'
        git checkout -b manifest-rev
        git checkout --detach manifest-rev
      '';
      installPhase = ''
        mkdir -p $out
        cp -r .git $out
      '';
    };
  projectsWithFakeGit = map (
    project:
    let
      path = project.path or project.name;
      src = fetchgit {
        inherit (project) url;
        inherit (project.nix) hash;
        fetchSubmodules = project.submodules or false;
        rev = project.revision;
      };
      fakegit = srcToFakeGit {
        inherit (project) name;
        inherit src;
      };
    in
    {
      inherit (project) name;
      inherit path src fakegit;
    }
  ) manifest'.manifest.projects;
  copyProjectsWithFakeGit = lib.concatStringsSep "\n" (
    map (project: ''
      echo Copying project ${project.name} with fake git repo
      __west2nix_copyProjectWithFakeGit ${project.src} ${project.fakegit} ${project.path}
    '') projectsWithFakeGit
  );
in
makeSetupHook {
  name = "west2nix-project-hook.sh";
  substitutions = {
    # Project path for `west init -l ...`
    path = manifest'.manifest.self.path or ".";
    inherit copyProjectsWithFakeGit;
  };
  passthru = {
    manifest = manifest';
    inherit projectsWithFakeGit;
  };
} ./project-hook.sh
