{ system ? builtins.currentSystem
, supportedSystems ? [ "x86_64-linux" "i686-linux" ]
, failBuildOnTestFailure ? "" }:

let pkgs = import ../../default.nix { inherit system; }; in

with pkgs.lib;

let
  testDriver = pkgs.nixtest;


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


  makeTest = { name,
               environment ? {},
               profile ? null,
               profilePackages ? [],
               skel ? null,
               sources ? {},
               symlinks ? {},
               testDir ? null,
               testFile ? null,
               testModule ? null,
  }:
    # It's either testDir + testModule or testFile
    assert testFile != null -> testDir == null;
    assert testFile != null -> testModule == null;
    assert testDir != null -> testModule != null;

    # Either you assemble your own profile or pass only packages.
    assert profile != null -> profilePackages == [];

    let
      _profile = if profile != null then profile else pkgs.buildEnv {
        name = "nix-test-${name}";
        paths = profilePackages;
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
      } // optionalAttrs (testDir != null) {
        NIXTEST_TESTDIR = testDir;
        NIXTEST_TESTMODULE = testModule;
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
          profilePackages = args.profilePackages or [];
        in
        makeTest (recursiveUpdate args {
          name = "${python.libPrefix}-${args.name}";

          profilePackages = [ pkgs.coreutils pkgs.bash ] ++ profilePackages;

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