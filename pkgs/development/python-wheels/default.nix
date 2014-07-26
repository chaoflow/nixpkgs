let
  pkgs = import ../../.. {};
in

{ callPackage ? pkgs.callPackage, lib ? pkgs.lib, python ? pkgs.python }:

let
  wheelsFor = python: self:
    let
      base = callPackage ./wheels-base.nix {} python self;
      meta = import ./wheels-meta.nix python self;
      requires = import ./wheels-requires.nix python self;
      wheels = callPackage ./wheels.nix {} python self;
    in
      base // (lib.mapAttrs
        (name: wheel: self.build ((lib.attrByPath [name] {} meta) //
                                  (lib.attrByPath [name] {} requires) //
                                  wheel))
        wheels);

  wheels = wheelsFor python wheels;

  wheelhouse = callPackage ./wheelhouse.nix {};
  all = wheelhouse {
    name = "${python.libPrefix}-wheelhouse-all-wheels";

    # Only include wheels in wheelhouse
    wheels = lib.filter (x: x.isWheel or false) (lib.attrValues wheels);
  };

in
  wheels // { inherit all; }