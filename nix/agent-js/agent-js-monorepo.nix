{ pkgs ? import ../. { inherit system; }
, system ? builtins.currentSystem
  # This should be a fs path to a checked-out agent-js git repo.
  # e.g. via niv at `nix-instantiate nix -A sources.agent-js-monorepo --eval`
, agent-js-monorepo-src
, agentJsMonorepoTools ? import ./monorepo-tools.nix { inherit pkgs system; }
}:
let
  npmEnvironmentBuildInput = (pkgs.stdenv.mkDerivation {
    name = "agent-js-monorepo-env";
    src = agent-js-monorepo-src;
    # Without this unsetting HOME, npm might try to write to default HOME=/homeless-shelter
    HOME = "";
    installPhase = ''
      mkdir -p $out
    '';
  });
  monorepo = pkgs.napalm.buildPackage agent-js-monorepo-src {
    name = "agent-js-monorepo";
    propagatedBuildInputs = [
      (agentJsMonorepoTools agent-js-monorepo-src)
      npmEnvironmentBuildInput
    ];
    buildInputs = [
      npmEnvironmentBuildInput
    ];
    outputs = [
      "out"
      "lib"
      "agent"
      "bootstrap"
    ];
    # HOME = "";
    npmCommands = [
      "npm install"
    ];
    installPhase = ''
      # $out: Everything!
      mkdir -p $out
      cp -R ./* $out/

      # $lib/node_modules: fetched npm dependencies
      mkdir -p $lib
      test -d node_modules && cp -R node_modules $lib || true

      # $agent: npm subpackage @dfinity/agent
      mkdir -p $agent
      cp -R node_modules $agent/
      cp -R ./packages/agent/* $agent/

      # $bootstrap: npm subpackage @dfinity/bootstrap
      mkdir -p $bootstrap
      cp -R node_modules $bootstrap/
      cp -R ./packages/bootstrap/* $bootstrap/
    '';
  };
in
monorepo
