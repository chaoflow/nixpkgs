#
# Wheelhouse - a collection of .whl files suitable for pip --find-links
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
