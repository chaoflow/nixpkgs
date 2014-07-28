{ system ? builtins.currentSystem
, supportedSystems ? [ "x86_64-linux" "i686-linux" ]
, failBuildOnTestFailure ? "" }:

let pkgs = import ../../default.nix { inherit system; }; in

with pkgs.lib;

let
  testDriver = pkgs.nixtest;


  # runTest runs test driver configured for one test (see makeTest
  # below). It also installs it into its output to allow for easy
  # re-runs ($out/bin/nixtest). A test failure is indicated by an
  # empty file: $out/nix-support/failed.
  #
  # TODO: log output suitable for hydra. nixtest uses python's logging
  # module. Log messages need to be caught and written to a log.xml
  # (see nixos/lib/test-driver for the format).
  runTest = driver:
    pkgs.stdenv.mkDerivation rec {
      name = "nixtest-run-${driver.testName}";
      passthru = {
        inherit system;
        isTest = true;
      };
      buildCommand =
        ''
          install -D ${driver}/bin/nixtest $out/bin/nixtest
          $out/bin/nixtest || failed=1

          if [ ! -z "$failed" ]; then
              mkdir -p $out/nix-support
              touch $out/nix-support/failed
              echo
              echo "FAIL: ${name}"
              echo "  to reproduce: ${driver}/bin/nixtest"
              echo "      to debug: ${driver}/bin/nixtest --ipdb"
              echo "      for help: ${driver}/bin/nixtest --help"
              echo
              if [ ! -z "${failBuildOnTestFailure}" ]; then
                  exit 2
              fi
          fi
        '';
    };


  makeTest =
    { name

    # An attribute set of additional environment variables to be set
    # in the test environment.
    , environment ? {}

    # You can either specify profilePackages which are added to a
    # profile created by buildEnv or create your own profile for full
    # control.
    , profile ? null
    , profilePackages ? []

    # skeleton directory for the test directory
    , skel ? null

    # sources to be copied to the test directory. It is ensured that
    # they are owned and writable by the test user.
    , sources ? {}

    # Additional symlinks to be created in the test directory. There
    # is at least one symlink for `profile`
    , symlinks ? {}

    # file containing the test code
    , testFile ? null}:

    # Either you assemble your own profile or pass only packages.
    assert profile != null -> profilePackages == [];

    let
      _profile = if profile != null then profile else pkgs.buildEnv {
        name = "nix-test-${name}";
        paths = [ pkgs.coreutils pkgs.bash ] ++ profilePackages;
      };

      # profile is just another symlink
      _symlinks = filterAttrs (n: v: v != null)
                              (symlinks // { profile = _profile; });

      # XXX: test and probably escape for values with spaces - needs
      # to be coordinated with how click parses
      attrsToEnvVar = attrs:
        concatStringsSep " "
          (map ({name, value}: concatStringsSep ":" [ name value ])
               (mapAttrsToList nameValuePair attrs));

      env = environment // {
        NIXTEST_SKEL = skel;
        NIXTEST_SYMLINKS = attrsToEnvVar _symlinks;
      } // optionalAttrs (testFile != null) {
        NIXTEST_TESTFILE = testFile;
      } // optionalAttrs (sources != {}) {
        NIXTEST_SOURCES = attrsToEnvVar sources;
      };

      setEnvironment = attrs: concatStrings (intersperse " " (map
        ({ name, value }: "--set ${name} '\"${value}\"'")
        (filter ({ name, value }: value != null)
                (mapAttrsToList nameValuePair attrs))));

      # create specific driver based on generic testDriver
      driver = pkgs.runCommand "test-driver-${name}"
        { buildInputs = [ pkgs.makeWrapper ];
          preferLocalBuild = true;
          testName = name + "-" + system;
        }
        ''
          install -D ${testDriver}/bin/nixtest $out/bin/nixtest

          wrapProgram $out/bin/nixtest ${setEnvironment env} \
            --add-flags --debug \
            --add-flags --testname --add-flags ${name}
        '';
    in
      runTest driver;


  makePythonTest =
    argsfn:
      { python, ... } @ testargs:
        let
          args = argsfn testargs;
        in
        makeTest (recursiveUpdate args {
          name = "${python.libPrefix}-${args.name}";

          environment = {
            TEST_PYTHON_LIB_PREFIX = python.libPrefix;
            TEST_PYTHON_EXECUTABLE = python.executable;
          };
        });


  forAllSystems = genAttrs supportedSystems;
  callPackage = pkgs.newScope callPackageScope;


  callTest = path: args: addAll (forAllSystems (system:
    let
      testlib = import ./. { inherit system failBuildOnTestFailure; };
    in
      testlib.callPackage path args
  ));


  callTestTree = path: args: 
    let
      tree = forAllSystems (system:
        let
          testlib = import ./. { inherit system failBuildOnTestFailure; };
        in
          testlib.callPackage path args);
    in
      addAll (fold
      (system: acc:
        recursiveUpdate acc (systemWrapLeaves system (getAttr system tree)))
      {}
      (attrNames tree));


  # i686-linux.foo.bar -> foo.bar.i686-linux
  # x86_64-linux.foo.bar -> foo.bar.x86_64-linux
  systemWrapLeaves = system: tree: fold
    (name: acc:
      let
        subtree = getAttr name tree;
      in
        if (subtree.isTest or false) then
          recursiveUpdate acc { ${name} = { ${system} = subtree; }; }
        else if ((isAttrs subtree) && ((subtree.type or "") != "derivation")) then
          recursiveUpdate acc { ${name} = addAll (systemWrapLeaves system subtree); }
        else
          # ignore
          acc
    )
    {}
    (attrNames tree);


  # For cli convenience add attribute sets to run all tests for all
  # supported systems and for the current system only.
  addAll = tree:
    let
      all = filter (x: x.system == system) allall;

      allall = concatMap
        (x: if (x.isTest or false) then
          [ x ]
        else if (isAttrs x) then
          x.allall
        else
          []
        )
        (attrValues allTree);

      allTree = mapAttrs
        (name: value: if (isAttrs value) then
          addAll value
        else
          value
        )
        tree;
    in
      allTree // rec { inherit all allall; };


  # scope for invocations of callPackage within test modules,
  # i.e. makeTest and makePythonTest are available in addition to the
  # defaultScope (pkgs and pkgs.xorg, see all-packages.nix).
  callPackageScope = { inherit
    callPackage
    makeTest
    makePythonTest
    ;
  };


  testlib = callPackageScope // { inherit
    addAll
    callTest
    callTestTree
    ;
  };

in
  testlib