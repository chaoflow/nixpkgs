#
# Run like e.g.:
#
# % nix-build tests -A python.all --argstr failBuildOnTestFailure 1
# % nix-build tests -A python.allall
#
# `all` and `allall` are added for (sub)trees of tests. `all` contains
# all tests for `system` and `allall` for all `supportedSystems`.
#
# XXX: adapt structure to what is needed by hydra
#
{ system ? builtins.currentSystem
, supportedSystems ? [ "x86_64-linux" "i686-linux" ]
, failBuildOnTestFailure ? ""
}:

with (import ./lib { inherit system; });

addAll
  { selftest = callTest ./selftest {};
    python = callTestTree ./python {};
  }
