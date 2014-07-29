#
# Wheelhouse - a collection of .whl files suitable for pip --find-links
#
# See nixpkgs/tests/python/virtualenv.py for an example
#
{ lib, python, stdenv }:

{ name ? "wheelhouse", wheels ? [], ...} @ attrs:

stdenv.mkDerivation ({
  inherit name wheels;
  unpackPhase = "true";
  installPhase =
    ''
      mkdir -p $out
      for wheel in $wheels; do
          ln -s $wheel/nix-support/?*.whl $out/
      done
    '';
} // attrs)
