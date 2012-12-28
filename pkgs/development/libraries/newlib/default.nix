{ stdenv, fetchurl, texinfo, cross ? null, gccCross ? null }:

assert cross != null -> gccCross != null;

let
  archMakeFlag = if (cross != null) then "ARCH=${cross.arch}" else "";
  crossMakeFlag = if (cross != null) then "CROSS=${cross.config}-" else "";

in
stdenv.mkDerivation rec {
  name = "newlib-1.20.0";

  src = fetchurl {
    url = "ftp://sources.redhat.com/pub/newlib/${name}.tar.gz";
    sha256 = "14pn7y1dm8vsm9lszfgkcz3sgdgsv1lxmpf2prbqq9s4fa2b4i66";
  };

  # Cross stripping hurts.
  dontStrip = if (cross != null) then true else false;

  makeFlags = [ crossMakeFlag "VERBOSE=1" ];

  buildInputs = stdenv.lib.optional (gccCross != null) gccCross;

  buildNativeInputs = [ texinfo ];

}