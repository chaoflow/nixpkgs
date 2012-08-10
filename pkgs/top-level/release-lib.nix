rec {
  allPackages = import ./all-packages.nix;

  pkgs = allPackages {};

  /* !!! Hack: poor man's memoisation function.  Necessary for prevent
     Nixpkgs from being evaluated again and again for every
     job/platform pair. */
  pkgsFor = system:
    if system == "x86_64-linux" then pkgs_x86_64_linux
    else if system == "i686-linux" then pkgs_i686_linux
    else if system == "x86_64-darwin" then pkgs_x86_64_darwin
    else if system == "i686-darwin" then pkgs_i686_darwin
    else if system == "x86_64-freebsd" then pkgs_x86_64_freebsd
    else if system == "i686-freebsd" then pkgs_i686_freebsd
    else if system == "i686-cygwin" then pkgs_i686_cygwin
    else abort "unsupported system type: ${system}";

  pkgs_x86_64_linux = allPackages { system = "x86_64-linux"; };
  pkgs_i686_linux = allPackages { system = "i686-linux"; };
  pkgs_x86_64_darwin = allPackages { system = "x86_64-darwin"; };
  pkgs_i686_darwin = allPackages { system = "i686-darwin"; };
  pkgs_x86_64_freebsd = allPackages { system = "x86_64-freebsd"; };
  pkgs_i686_freebsd = allPackages { system = "i686-freebsd"; };
  pkgs_i686_cygwin = allPackages { system = "i686-cygwin"; };

  /* The working or failing mails for cross builds will be sent only to
     the following maintainers, as most package maintainers will not be
     interested in the result of cross building a package. */
  crossMaintainers = with pkgs.lib.maintainers; [ viric ];

  /* Set the Hydra scheduling priority for a job.  The default
     priority (10) should be used for most jobs.  A different
     priority should only be used for a few particularly interesting
     jobs (in terms of giving feedback to developers), such as stdenv.
  */
  prio = level: job: toJob job // { schedulingPriority = level; };

  toJob = x: if builtins.isAttrs x then x else
    { type = "job"; systems = x; schedulingPriority = 4; };

  /* Perform a job on the given set of platforms.  The function `f' is
     called by Hydra for each platform, and should return some job
     to build on that platform.  `f' is passed the Nixpkgs collection
     for the platform in question. */
  testOn = systems: f: {system ? builtins.currentSystem}:
    if pkgs.lib.elem system systems then f (pkgsFor system) else {};

  /* Similar to the testOn function, but with an additional 'crossSystem'
   * parameter for allPackages, defining the target platform for cross builds */
  testOnCross = crossSystem: systems: f: {system ? builtins.currentSystem}:
    if pkgs.lib.elem system systems then f (allPackages {inherit system
                crossSystem;}) else {};

  /* Map an attribute of the form `foo = [platforms...]'  to `testOn
     [platforms...] (pkgs: pkgs.foo)'. */
  mapTestOn = pkgs.lib.mapAttrsRecursiveCond
    (as: !(as ? type && as.type == "job"))
    (path: value:
      let
        job = toJob value;
        getPkg = pkgs:
          pkgs.lib.addMetaAttrs { schedulingPriority = toString job.schedulingPriority; }
          (pkgs.lib.getAttrFromPath path pkgs);
      in testOn job.systems getPkg);


  /* Similar to the testOn function, but with an additional 'crossSystem'
   * parameter for allPackages, defining the target platform for cross builds,
   * and triggering the build of the host derivation (cross built - hostDrv). */
  mapTestOnCross = crossSystem: pkgs.lib.mapAttrsRecursiveCond
    (as: !(as ? type && as.type == "job"))
    (path: value:
      let
        job = toJob value;
        getPkg = pkgs: (pkgs.lib.addMetaAttrs {
            schedulingPriority = toString job.schedulingPriority;
            maintainers = crossMaintainers; 
          }
          (pkgs.lib.getAttrFromPath path pkgs));
      in testOnCross crossSystem job.systems getPkg);

  /* Find all packages that have a meta.platforms field listing the
     supported platforms. */
  condPackagesWithMetaPlatform = validPlatforms: pred: attrSet:
    if builtins ? tryEval then 
      let pairs = pkgs.lib.concatMap 
        (x:
	  let pair = builtins.tryEval
	        (let 
		   attrVal = (builtins.getAttr x attrSet);
		 in
		   {val=(condProcessPackage validPlatforms pred attrVal);
		    attrVal = attrVal;
		    attrValIsAttrs = builtins.isAttrs attrVal;
		    });
	      success = (builtins.tryEval pair.value.attrVal).success;
	  in
          if success && pair.value.attrValIsAttrs && 
	      pair.value.val != [] then 
	    [{name= x; value=pair.value.val;}] else [])
        (builtins.attrNames attrSet);
      in
        builtins.listToAttrs pairs
    else {};

  packagesWithMetaPlatform = condPackagesWithMetaPlatform pkgs.lib.platforms.all (x: true);

  # May fail as much as it wishes, we will catch the error.
  condProcessPackage = validPlatforms: pred: attrSet:
    if attrSet ? recurseForDerivations && attrSet.recurseForDerivations then
      condPackagesWithMetaPlatform validPlatforms pred attrSet
    else if attrSet ? recurseForRelease && attrSet.recurseForRelease then
      condPackagesWithMetaPlatform validPlatforms pred attrSet
    else
      if attrSet ? meta && attrSet.meta ? platforms &&
          pkgs.lib.intersect validPlatforms attrSet.meta.platforms != [] &&
          pred attrSet
        then pkgs.lib.intersect validPlatforms attrSet.meta.platforms
        else [];

  processPackage = condProcessPackage pkgs.lib.platforms.all (x: true);


  # get a list of all inputs, excluding null inputs and string inputs
  # depth 0 returns the derivation itself,
  # depth 1 are direct inputs,
  # depth 2 are direct inputs of direct inputs, ...
  # TODO: resolve string inputs to derivations?
  getInputs = depth: attrSet:
    let
      inputs = pkgs.lib.filter
        (x: x != null && ! builtins.isString x)
        ((pkgs.lib.getAttrDefault "buildInputs" attrSet []) ++
         (pkgs.lib.getAttrDefault "buildNativeInputs" attrSet []) ++
         (pkgs.lib.getAttrDefault "propagatedBuildInputs" attrSet []) ++
         (pkgs.lib.getAttrDefault "propagatedBuildNativeInputs" attrSet []) );
    in
      if depth == 0
        then [ attrSet ]
        else inputs ++ (pkgs.lib.concatMap (getInputs (builtins.sub depth 1)) inputs);
      

  # return true if a derivation depends on one of the dependencies
  dependsOn = depth: dependencies: attrSet:
    let
      inputs = getInputs depth attrSet;
    in
      pkgs.lib.intersect dependencies inputs != [];


  /* Common platform groups on which to test packages. */
  inherit (pkgs.lib.platforms) linux darwin cygwin allBut all mesaPlatforms;

  /* Platform groups for specific kinds of applications. */
  x11Supported = linux;
  gtkSupported = linux;
  ghcSupported = linux ++ ["i686-darwin"] ;

}
