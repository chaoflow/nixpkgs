{ stdenv, fetchurl, pkgconfig, perl, perlXMLParser, gtk, libXft
, libpng, zlib, popt, boehmgc, libxml2, libxslt, glib, gtkmm
, glibmm, libsigcxx, lcms, boost, gettext, makeWrapper, intltool
, gsl, poppler, python, imagemagick, libwpg }:

let
  pysite = python.site {
    wheels = [ python.wheels.lxml python.wheels.pyxml ];
  };
in

stdenv.mkDerivation rec {
  name = "inkscape-0.48.5";
  passthru = { python = pysite; };

  src = fetchurl {
    url = "mirror://sourceforge/inkscape/${name}.tar.bz2";
    sha256 = "0sfr7a1vr1066rrkkqbqvcqs3gawalj68ralnhd6k87jz62fcv1b";
  };

  patches = [ ./configure-python-libs.patch ];

  postPatch = stdenv.lib.optionalString doCheck
    ''sed -i 's:#include "../../src:#include "src:' src/cxxtests.cpp'';

  buildInputs = [
    pkgconfig perl perlXMLParser gtk libXft libpng zlib popt boehmgc
    libxml2 libxslt glib gtkmm glibmm libsigcxx lcms boost gettext
    makeWrapper intltool gsl poppler imagemagick libwpg pysite
  ];

  configureFlags = "--with-python";

  enableParallelBuilding = true;
  doCheck = true;
  checkFlags = "-j1";

  postInstall = ''
    rm "$out/share/icons/hicolor/icon-theme.cache"
    # inkscape needs to find the python with lxml/pyxml
    for prg in "$out/bin/"*; do
        wrapProgram "$prg" --prefix PATH ":" "${pysite}/bin" || exit 2
    done
  '';

  NIX_LDFLAGS = "-lX11";

  meta = with stdenv.lib; {
    license = "GPL";
    homepage = http://www.inkscape.org;
    description = "Vector graphics editor";
    platforms = platforms.all;
    longDescription = ''
      Inkscape is a feature-rich vector graphics editor that edits
      files in the W3C SVG (Scalable Vector Graphics) file format.

      If you want to import .eps files install ps2edit.
    '';
  };
}
