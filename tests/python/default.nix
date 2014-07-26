{ callPackage, pkgs }:

{
  availableModules = callPackage ./available-modules.nix {};
  buildout = callPackage ./buildout.nix {};
  virtualenv = callPackage ./virtualenv.nix {};
}