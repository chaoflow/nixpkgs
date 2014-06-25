#
# python tests
#
# - Please add your test scenarios
#
# - All tests in the "all" attr set are found by hydra, except if you
#   add their name to skip in release.nix
#
# - If you are unsure, please make a pull request and ping e.g. chaoflow
#
# Run like:
#
# % nix-build python.nix -A virtualenv.python27 --arg debug true
#
{ system ? builtins.currentSystem, debug ? false }:

with import ../lib/testing.nix { inherit system; };
with pkgs.lib;

let
  full = python: hasSuffix "-wrapper" python.name;
  libPrefix = python: python.libPrefix or python.python.libPrefix;
  machine = { python, packageNames ? [] }:
    let
      _full = full python;
      pythonModules = optionalAttrs (!_full) python.modules;
      attrName = (replaceChars ["."] [""] (libPrefix python));
      pythonPackages = getAttr (attrName + "Packages") pkgs;
      # XXX: recursivePthLoader should be pushed by buildPythonPackage
      extraPackages = optional (!_full) pythonPackages.recursivePthLoader;
      systemPackages = extraPackages ++
        (map (x: getAttr x pythonPackages) packageNames) ++
        [ python ] ++ (filter (v: (v.type or null) == "derivation")
                              (attrValues pythonModules));
    in {
      environment.systemPackages = systemPackages;
    };

  # slow
  replaceSubstring = old: new: str:
    concatStrings (intersperse new (splitString old str));

  # evaluated every time, not nice
  # consider passing vars via environment variables
  substitute = attrs: str:
    let replaceVar = name: _str:
          replaceSubstring "@${name}@" (getAttr name attrs) _str;
    in fold replaceVar str (attrNames attrs);

  perlBool = bool:
    if bool then "true" else "";

  testScriptPreamble = { name, python }:
    substitute { debug = perlBool debug;
                 full = perlBool (full python);
                 libPrefix = libPrefix python;
                 inherit name;
               }
               (readFile ./python/preamble.pl);

  makePythonTest = _name: testScript: packageNames:
    { python }:
      let name = "${_name}-${libPrefix python}";
      in makeTest
           { name = name;
             machine = machine { inherit python packageNames;};
             testScript =
               testScriptPreamble { inherit name python; } +
               testScript;
           };

  testScriptProfile = readFile ./python/profile.pl;
  testScriptDevpkg = readFile ./python/devpkg.pl;
  testScriptVirtualenv = readFile ./python/virtualenv.pl;
  testScriptBuildout = readFile ./python/buildout.pl;

  makeProfileTest = makePythonTest "profile"
    testScriptProfile
    ["flake8" "nose"];

  makeVirtualenvTest = makePythonTest "virtualenv"
    (testScriptDevpkg + testScriptVirtualenv)
    ["dateutil" "flake8" "ldap" "nose" "recursivePthLoader" "virtualenv"];

  makeBuildout171Test = makePythonTest "buildout171"
    (testScriptDevpkg + testScriptBuildout)
    ["dateutil" "flake8" "ldap" "nose" "virtualenv" "zc_buildout171"
     "zc_recipe_egg_buildout171"];

  makeBuildout2Test = makePythonTest "buildout2"
    (testScriptDevpkg + testScriptBuildout)
    ["dateutil" "flake8" "ldap" "nose" "virtualenv" "zc_buildout2"
     "zc_recipe_egg_buildout2"];



in rec {

  #### Tests grouped by test cases

  buildout171 = {
    python26 = makeBuildout171Test { python = pkgs.python26; };
    python26Full = makeBuildout171Test { python = pkgs.python26Full; };
    python27 = makeBuildout171Test { python = pkgs.python27; };
    python27Full = makeBuildout171Test { python = pkgs.python27Full; };
  };

  buildout2 = {
    python26 = makeBuildout2Test { python = pkgs.python26; };
    python26Full = makeBuildout2Test { python = pkgs.python26Full; };
    python27 = makeBuildout2Test { python = pkgs.python27; };
    python27Full = makeBuildout2Test { python = pkgs.python27Full; };
  };

  profile = {
    python26 = makeProfileTest { python = pkgs.python26; };
    python26Full = makeProfileTest { python = pkgs.python26Full; };
    python27 = makeProfileTest { python = pkgs.python27; };
    python27Full = makeProfileTest { python = pkgs.python27Full; };
  };

  virtualenv = {
    # virtualenv pip fails with: ImportError: cannot import name HTTPSHandler
    # likely this is caused by ssl module not being found
    # 2.7 includes ssl without "full", 2.6 only with "full"
    python26 = makeVirtualenvTest { python = pkgs.python26; };
    python26Full = makeVirtualenvTest { python = pkgs.python26Full; };
    python27 = makeVirtualenvTest { python = pkgs.python27; };
    python27Full = makeVirtualenvTest { python = pkgs.python27Full; };
  };

  ##### Tests grouped by python version

  python26 = {
    buildout171 = buildout171.python26;
    buildout2 = buildout2.python26;
    profile = profile.python26;
    virtualenv = virtualenv.python26;
  };

  python26Full = {
    buildout171 = buildout171.python26Full;
    buildout2 = buildout2.python26Full;
    profile = profile.python26Full;
    virtualenv = virtualenv.python26Full;
  };

  python27 = {
    buildout171 = buildout171.python27;
    buildout2 = buildout2.python27;
    profile = profile.python27;
    virtualenv = virtualenv.python27;
  };

  python27Full = {
    buildout171 = buildout171.python27Full;
    buildout2 = buildout2.python27Full;
    profile = profile.python27Full;
    virtualenv = virtualenv.python27Full;
  };

  #### All python tests for all versions

  all = {
    buildout171Python26 = buildout171.python26;
    buildout171Python26Full = buildout171.python26Full;
    buildout171Python27 = buildout171.python27;
    buildout171Python27Full = buildout171.python27Full;
    buildout2Python26 = buildout2.python26;
    buildout2Python26Full = buildout2.python26Full;
    buildout2Python27 = buildout2.python27;
    buildout2Python27Full = buildout2.python27Full;
    profilePython26 = profile.python26;
    profilePython26Full = profile.python26Full;
    profilePython27 = profile.python27;
    profilePython27Full = profile.python27Full;
    virtualenvPython26 = virtualenv.python26;
    virtualenvPython26Full = virtualenv.python26Full;
    virtualenvPython27 = virtualenv.python27;
    virtualenvPython27Full = virtualenv.python27Full;
  };
}
