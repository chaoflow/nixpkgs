#
# Default set of wheels.
#
# you can build from within this folder for the default python version:
# nix-build -A ipdb
# nix-build -A all
#
# wheels are carried by each python version:
# nix-build -A pkgs.python27.wheels.all
# nix-build -A pkgs.python34.wheels.ipdb
#
let
  pkgs = import ../../.. {};
in

{ callPackage ? pkgs.callPackage, lib ? pkgs.lib, python ? pkgs.python }:

let
  # wheelsFor creates a self-referential set of wheels for a specific
  # python version.
  wheelsFor = python: self:
    let
      # base provides wheels.build and some wheels that need special
      # treatment because of bootstrapping.
      base = callPackage ./wheels-base.nix {} python self;

      # meta information for wheels, intended to be generated from
      # dist-info. You can override by providing meta in wheels.nix.
      meta = import ./wheels-meta.nix python self;

      # requires information for wheels, intended to be generated from
      # dist-info. You can override by providing requires in wheels.nix.
      requires = import ./wheels-requires.nix python self;

      # wheels specification
      wheels = callPackage ./wheels.nix {} python self;
    in
      base // (lib.mapAttrs
        (name: wheelspec:
          let
            # merge meta, requires and wheel spec and use base.build
            # to create the wheel.
            wheel = self.build ((lib.attrByPath [name] {} meta) //
                                (lib.attrByPath [name] {} requires) //
                                wheelspec);
          in wheel)
        wheels);

  # self-referential set of wheels.
  wheels = wheelsFor python wheels;

  # A wheelhouse is folder with (links to) .whl files.
  wheelhouse = callPackage ./wheelhouse.nix {};

  # Wheelhouse containing all wheels we know about. The wheels are
  # also available as a list via wheels.all.wheels.
  all = wheelhouse {
    name = "${python.libPrefix}-wheelhouse-all-wheels";

    # Only include wheels in wheelhouse
    wheels = lib.filter (x: x.isWheel or false) (lib.attrValues wheels);
  };

in
  wheels // { inherit all; }