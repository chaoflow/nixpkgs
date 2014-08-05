#
# A python.site comes closest to python on other distributions with:
#
# - bin/python
# - bin/<scripts for packages>
# - lib/pythonX.Y
# - lib/pythonX.Y/site-packages
#
# Additionally you can add non-python packages to be merged in (see
# paths arg below).
#
{ buildEnv, callPackage, lib, makeWrapper, python, python27, stdenv }:

let
  # The default pickPolicy in case of multiple wheels with the same
  # distname simple picks the first one encountered.
  firstInList = cur: new: false;
in

{ name ? ""

# By default all modules that ship with python are added to the python
# site. By specifying a list of modules here you can add them
# selectively.
, modules ? null

# List of wheels to be added to the python site. Requirements will be
# added automatically.
#
# XXX: Currently requirements definitions are incomplete and you might
# need to specify manually.
, wheels ? []

# List of non-wheel paths to be passed to buildEnv, e.g. if you need
# openldap or something.
, paths ? []

# Currently, by default only the scripts are generated for python
# packages/wheels you specify here. We might switch to default all and
# use this parameter for selective generation.
, scriptsFor ? []

# Do something after the site is generated
, postBuild ? ""

# A pickPolicy is used to choose a wheel in case there are multiple
# wheels with the same name in the list of wheels you specified +
# their dependencies. pickPolicy takes the currently picked wheel and
# the new wheel (see firstInList above). If it returns true, the new
# wheel will be picked.
, pickPolicy ? firstInList

# most attrs are passed on to buildEnv, for exceptions see omitAttrs
# below.
, ... } @ attrs:


assert lib.all (x: x.python == python) wheels;


let
  omitAttrs = [ "name" "modules" "passthru" "wheels" "postBuild"
                "scriptsFor" "pickPolicy" "paths" ];
  filteredAttrs = lib.filterAttrs (n: v: ! lib.elem n omitAttrs) attrs;

  scriptdists = lib.concatStringsSep " " scriptsFor;

  recursiveRequires = wheels:
    lib.flatten (map
      (whl: [ whl ] ++ (recursiveRequires (whl.requires)))
      (lib.filter (x: x != null) wheels));

  allModules = if python.isPy2 or false then
    lib.filter (v: v != null) (lib.attrValues python.modules)
  else
    []
  ;

  unveil = python27.tool {
    wheel = python27.wheels.unveil;
    doInstallCheck = true;
    installCheckPhase = "$out/bin/unveil --help";
  };

  pickVersions = wheels:
    lib.attrValues (lib.fold
      (wheel: acc: if (acc.${wheel.distname} or null != null) then
        if (pickPolicy (lib.getAttr wheel.distname acc) wheel) then
          acc // { ${wheel.distname} = wheel; }
        else
          acc
      else
        acc // { ${wheel.distname} = wheel; }
      )
      {}
      wheels);

  resolvedWheels = if (pickPolicy != null) then
    pickVersions (recursiveRequires wheels)
  else
    recursiveRequires wheels;

  wheelhouse = callPackage ./wheelhouse.nix {} { wheels = resolvedWheels; };


in
buildEnv (lib.recursiveUpdate {
  name = "${python.libPrefix}-site" + lib.optionalString (name != "") "-${name}";
  paths =
    [ python ] ++
    (if modules == null then allModules else modules) ++
    (resolvedWheels) ++
    paths;
  passthru = {
    inherit modules python wheels wheelhouse;
    inherit (python) executable libPrefix sitePackages;
  };
  postBuild =
    ''
      # buildEnv has no buildInputs, we'd like makeWrapper to be available
      . "${makeWrapper}/nix-support/setup-hook"

      # If bin is a link, it is coming fully from python
      if [ -L "$out/bin" ]; then
          unlink "$out/bin"
          mkdir -p "$out/bin"
          cd "$out/bin"
          for prg in "${python}/bin/"*; do
              ln -s "$prg" "$(basename "$prg")"
          done
      fi
      mkdir -p "$out/bin"

      # create wrappers setting python home for everything in the env's bin
      for prg in "$out/bin/"*; do
          wrapProgram "$prg" --set PYTHONHOME "$out"
      done
    '' + (lib.optionalString (scriptsFor != [])
    ''
      for dist in ${scriptdists}; do
          "${unveil}/bin/unveil" create-scripts \
              --target "$out/bin" \
              --python "$out/bin/${python.executable}" \
              --dist "$dist/${python.sitePackages}/"*.dist-info
      done
    '') + postBuild;
} filteredAttrs)
