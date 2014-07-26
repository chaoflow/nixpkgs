{ lib, makeWrapper, python, python27, stdenv }:

let
  build = { name ? null
          , src ? null
          , buildInputs ? []
          , requires ? []
          , wheel ? null
          , wheels ? []
          , pickPolicy ? null
          , ... } @ attrs:

    assert wheel == null -> name != null && src != null;
    assert src == null -> wheel != null;
    assert name == null -> wheel != null;
    assert wheel != null -> requires == [];

    let
      _wheel = if (wheel != null) then wheel else python.wheels.build {
        inherit name src buildInputs requires;
      };
      omitAttrs = [ "name" "src" "wheel" "wheels" "buildInputs"
                    "requires" "pickPolicy" ];
      filteredAttrs = lib.filterAttrs (n: v: ! lib.elem n omitAttrs) attrs;

      _name = "${_wheel.distname}-${_wheel.version}";

      unveilPython = python27;
      unveilWheels = with unveilPython.wheels; [ click unveil ];
      unveilPythonpath = lib.makeSearchPath unveilPython.sitePackages unveilWheels;

      site = python.site {
        name = _name;
        modules = lib.optionals (python.isPy2 or false)
                                [ python.modules.readline python.modules.sqlite3 ];
        wheels = wheels ++ [ _wheel ];
        inherit pickPolicy;
      };

    in
      stdenv.mkDerivation ({
        inherit site;
        name = _name;
        wheel = _wheel;
        buildInputs = [ site ];
        unpackPhase = "true";
        installPhase =
          ''
            mkdir -p $out/bin
            mkdir -p $out/nix-support
            ln -s $site $out/nix-support/site

            # Create scripts for our distribution
            # pyscripts will also check for non-entry_point scripts in .data
            PYTHONPATH="${unveilPythonpath}" \
                "${unveilPython}/bin/${unveilPython.executable}" \
                -m unveil \
                create-scripts \
                --target "$out/bin" \
                --python "$site/bin/${python.executable}" \
                --dist "$wheel/${python.sitePackages}/"*.dist-info
          '';
      } // filteredAttrs);

in
  build
