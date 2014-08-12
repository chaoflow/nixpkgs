#
# A python.tool generates the scripts for one python wheel. It creates
# a python.site behind the scenes. The wheel can be created
# implicitly.
#
{ lib, makeWrapper, python, python27, stdenv }:

{ name ? null

# wheel to create scripts for
, wheel ? null

# additional wheels to be made available
# XXX: eh - why's that?
, wheels ? []

# Instead of passing a wheel, src, buildInputs and requires can be
# passed to create a wheel. These are passed as is to the
# python.wheels.build function.
, src ? null
, buildInputs ? []
, requires ? []

# A pickPolicy is used to choose a wheel in case there are multiple
# wheels with the same name in the list of wheels you specified +
# their dependencies. pickPolicy takes the currently picked wheel and
# the new wheel (see site.nix/firstInList). If it returns true, the
# new wheel will be picked.
, pickPolicy ? null

# most attrs are passed on to buildEnv, for exceptions see omitAttrs
# below.
, ... } @ attrs:


assert wheel == null -> name != null && src != null;
assert src == null -> wheel != null;
assert name == null -> wheel != null;
assert wheel != null -> requires == [];


let
  omitAttrs = [ "name" "src" "wheel" "wheels" "buildInputs"
                "requires" "pickPolicy" ];
  filteredAttrs = lib.filterAttrs (n: v: ! lib.elem n omitAttrs) attrs;

  _wheel = if (wheel != null) then wheel else python.wheels.build {
    inherit name src buildInputs requires;
  };

  _name = "${_wheel.distname}-${_wheel.version}";

  unveilPython = python27;
  unveilWheels = with unveilPython.wheels; [ click unveil ];
  unveilPythonpath = lib.makeSearchPath unveilPython.sitePackages unveilWheels;

  site = python.site {
    name = _name;
    wheels = wheels ++ [ _wheel ];
    scriptsFor = [];
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
} // filteredAttrs)
