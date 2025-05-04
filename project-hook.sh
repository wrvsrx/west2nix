# West only considers proper git repos when discovering projects.
# Hack around this by creating fake git repos for each project:
function __west2nix_copyProjectWithFakeGit {
    mkdir -p $(dirname "$3")
    cp -r "$1" "$3"
    chmod -R +w "$3"
    cp -r "$2"/.git "$3"/.git
}

function __west2nix_copyProjectsHook {
    echo "Executing __west2nix_copyProjectsHook"

    @copyProjectsWithFakeGit@
}


function __west2nix_configureHook {
    echo "Executing __west2nix_configureHook"

    west init -l @path@
    cd @path@
}

function __west2nix_buildPhase {
    echo "Executing __west2nix_buildPhase"

    runHook preBuild
    west build $westBuildFlags
    runHook postBuild
}

postConfigureHooks+=(__west2nix_copyProjectsHook)

if [ -z "${dontUseWestConfigure-}" ] && [ -z "${configurePhase-}" ]; then
    echo "Using __west2nix_configureHook"
    postConfigureHooks+=(__west2nix_configureHook)
fi

if [ -z "${dontUseWestBuild-}" ] && [ -z "${buildPhase-}" ]; then
    echo "Using __west2nix_buildPhase"
    buildPhase=__west2nix_buildPhase
fi
