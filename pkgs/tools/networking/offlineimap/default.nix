{ fetchurl, lib, python2 }:

let
  version = "6.5.6";

in
# XXX: needs at least sqlite3, maybe also readline, currently added
# by tools.build
python2.tool rec {
  name = "offlineimap-${version}";

  src = fetchurl {
    url = "https://github.com/OfflineIMAP/offlineimap/archive/v${version}.tar.gz";
    sha256 = "1hr8yxb6r8lmdzzly4hafa1l1z9pfx14rsgc8qiy2zxfpg6ijcn2";
  };

  meta = {
    description = "Synchronize emails between two repositories, so that you can read the same mailbox from multiple computers";
    homepage = "http://offlineimap.org";
    license = lib.licenses.gpl2Plus;
    maintainers = [ lib.maintainers.garbas ];
  };

  doInstallCheck = true;
  installCheckPhase = "$out/bin/offlineimap --version";
}
