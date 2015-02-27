{ buildEnv, callPackage, lib, makeWrapper, python, python27, stdenv }:

let
  firstInList = cur: new: false;
in

{ name ? ""
, modules ? null
, wheels ? []
, paths ? []
, scriptsFor ? []
, postBuild ? ""
, pickPolicy ? firstInList
, ... } @ attrs:

assert lib.all (x: x.python == python) wheels;

let
  omitAttrs = [ "name" "modules" "passthru" "wheels" "postBuild" "scriptsFor"
                "pickPolicy" ];
  filteredAttrs = lib.filterAttrs (n: v: ! lib.elem n omitAttrs) attrs;
  scriptdists = lib.concatStringsSep " " scriptsFor;
  recursiveRequires = wheels:
    lib.flatten (map
      (whl: [ whl ] ++ (recursiveRequires (whl.requires)))
      wheels);

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
