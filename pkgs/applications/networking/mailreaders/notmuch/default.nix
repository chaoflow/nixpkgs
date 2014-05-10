{ fetchurl, stdenv, bash, dtach, emacs, gdb, glib, gmime, gnupg,
  perl, pkgconfig, python27, python27Packages, talloc, xapian
}:

stdenv.mkDerivation rec {
  name = "notmuch-0.18";

  src = fetchurl {
    url = "http://notmuchmail.org/releases/${name}.tar.gz";
    sha256 = "1ia65iazz2hlp3ja57yn0chs27rzsky9kayw74njwmgi9faw3vh9";
  };

  buildInputs = [ bash dtach emacs gdb glib gmime gnupg perl pkgconfig python27 python27Packages.sphinx talloc xapian ];

  patchPhase = ''
    patchShebangs test
    for src in \
      crypto.c \
      emacs/notmuch-crypto.el
    do
      substituteInPlace "$src" \
        --replace \"gpg\" \"${gnupg}/bin/gpg2\"
    done
  '';

  # XXX: couple of tests broken
  doCheck = false;
  checkTarget = "test";

  meta = {
    description = "Notmuch -- The mail indexer";
    longDescription = "";
    license = stdenv.lib.licenses.gpl3;
    maintainers = with stdenv.lib.maintainers; [ chaoflow garbas ];
    platforms = stdenv.lib.platforms.gnu;
  };
}
