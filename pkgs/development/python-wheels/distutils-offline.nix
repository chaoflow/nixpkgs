{ stdenv, python }:

stdenv.mkDerivation {
  name = "${python.libPrefix}-distutils-offline.cfg";
  buildInputs = [ python ];
  unpackPhase = "true";
  installPhase =
    ''
      dest="$out/${python.sitePackages}/distutils"
      mkdir -p $dest
      ln -s "${python}/lib/${python.libPrefix}/"* $dest/
      ln -s ./distutils-offline.cfg  $dest/distutils.cfg
    '';
}