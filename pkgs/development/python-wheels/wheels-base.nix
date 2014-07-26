#
# wheels.build function and wheels needed by it
#
{ callPackage, fetchurl, lib, stdenv, unzip }:

# Called like:
# wheels = baseFor python wheels;
python: self: {
  _build = bdistWheelDeps:
    { disable ? false
    , name
    , src ? null
    , md5 ? ""
    , sha256 ? ""
    , format ? "tar.gz"
    , buildInputs ? []
    , requires ? []
    , passthru ? {}
    , ...} @ attrs:

    assert src == null -> md5 != "" || sha256 != "";
    assert sha256 != "" -> md5 == "";

    let
      # These attributes are not (directly) passed to mkDerivation
      omitAttrs = [ "buildInputs" "name" "format" "md5" "sha256"
                    "requires" "src" "distname" "version" "passthru" ];
      filteredAttrs = lib.filterAttrs (n: v: ! lib.elem n omitAttrs) attrs;

      version = (builtins.parseDrvName name).version;
      distname = lib.removeSuffix "-${version}" name;

      _src = if src != null then src else (fetchurl {
        inherit md5 sha256;
        url = "https://pypi.python.org/packages/source/" +
          "${lib.substring 0 1 distname}/${distname}/${distname}-${version}.${format}";
      });

      _passthru = {
        inherit distname python requires test version;
        isWheel = true;
      } // passthru;

      _bdistWheelDeps =
        [ (callPackage ./distutils-offline.nix {})
        ] ++ (lib.filter (x: x != null) (lib.attrValues bdistWheelDeps));
      pythonpath = lib.makeSearchPath python.sitePackages _bdistWheelDeps;

      wheel = if disable then null else stdenv.mkDerivation ({
        passthru = _passthru;
        name = "${python.libPrefix}-wheel-${distname}-${version}";
        src = _src;
        buildInputs = [ python unzip ] ++ buildInputs;
        buildPhase = "true";
        installPhase =
          ''
            runHook preInstall

            # enforce setuptools as build system by enabling it to
            # patch distutils for packages that do not use setuptools
            sed -i '0,/import distutils/s//import setuptools;import distutils/' setup.py
            sed -i '0,/from distutils/s//import setuptools;from distutils/' setup.py

            # create wheel, the compressed wheel itself is (currently)
            # only used by wheelhouses who take them from nix-support
            mkdir -p $out/nix-support
            PYTHONPATH=${pythonpath} ${python.executable} \
                setup.py bdist_wheel -d $out/nix-support

            # unzip wheel to site-packages
            #
            # XXX: This is a temporary solution to enable
            # runtime-dependency detection. Also, for now, we use
            # wheels in that form to build environments, bending the
            # wheel specification. We might end up unpacking wheels
            # when creating sites. In that case, the whl would be
            # toplevel and we would run the runtime-dependency checks
            # ourselves and create a propagatedBuildInputs.
            mkdir -p $out/${python.sitePackages}
            unzip -d $out/${python.sitePackages} $out/nix-support/?*.whl

            runHook postInstall
          '';
      } // filteredAttrs);

    in
      wheel;

  # function to build wheels
  build = self._build { inherit (self) argparse setuptools wheel; };

  # wheels for bootstrapping wheels, don't use for anything else
  _bootstrap = {
    argparse = if (python.isPy26 or false) then (stdenv.mkDerivation {
      name = "${python.libPrefix}-bootstrap-wheel-argparse-1.2.1";
      src = fetchurl {
        url = https://pypi.python.org/packages/source/a/argparse/argparse-1.2.1.tar.gz;
        md5 = "2fbef8cb61e506c706957ab6e135840c";
      };
      passthru = { inherit python; };
      installPhase =
        ''
          mkdir -p $out/${python.sitePackages}
          cp argparse.py $out/${python.sitePackages}/
        '';
    }) else null;

    setuptools = stdenv.mkDerivation {
      name = "${python.libPrefix}-bootstrapwheel-setuptools-5.4.1";
      src = fetchurl {
        url = https://pypi.python.org/packages/3.4/s/setuptools/setuptools-5.4.1-py2.py3-none-any.whl;
        md5 = "5b7b07029ad2285d1cbf809a8ceaea08";
      };
      passthru = { inherit python; };
      buildInputs = [ unzip ];
      unpackPhase = "true";
      installPhase =
        ''
          mkdir -p $out/${python.sitePackages}
          unzip -d $out/${python.sitePackages} $src
        '';
    };

    wheel = stdenv.mkDerivation {
      name = "${python.libPrefix}-bootstrapwheel-wheel-0.24.0";
      src = fetchurl {
        url = https://pypi.python.org/packages/py2.py3/w/wheel/wheel-0.24.0-py2.py3-none-any.whl;
        md5 = "4c24453cda2177fd42c5d62d6434679a";
      };
      passthru = { inherit python; };
      buildInputs = [ unzip ];
      unpackPhase = "true";
      installPhase =
        ''
          mkdir -p $out/${python.sitePackages}
          unzip -d $out/${python.sitePackages} $src 
        '';
    };
  };

  argparse = self._build {
    inherit (self._bootstrap) argparse setuptools wheel;
  } rec {
    name = "argparse-1.2.1";
    md5 = "2fbef8cb61e506c706957ab6e135840c";
    disable = ! (python.isPy26 or false);
  };

  setuptools = self._build {
    inherit (self) argparse;
    inherit (self._bootstrap) setuptools wheel;
  } rec {
    name = "setuptools-5.4.1";
    md5 = "3540a44b90017cbb851840934156848e";
  }; 

  wheel = self._build {
    inherit (self) argparse setuptools;
    inherit (self._bootstrap) wheel;
  } rec {
    name = "wheel-0.24.0";
    md5 = "3b0d66f0d127ea8befaa5d11453107fd";
  };
}
