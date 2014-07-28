#
# selftest of the test system
#
{ makeTest, pkgs }:

makeTest {
  name = "selftest";

  # test file to be run by nixtest
  testFile = ./test.py;

  # skeleton for the test directory
  skel = ./skel;

  # environment variables to be set
  environment = {
    foo = "one";
    bar = "two";
  };

  # packages to be added to the profile used by nixtest as test
  # environment. The profile is also symlinked into the test directory
  # as `profile`.
  profilePackages = [ pkgs.coreutils pkgs.hello ];

  # Additional symlinks to be created in the test directory
  symlinks = {
    profile1 = pkgs.buildEnv {
      name = "profile1";
      paths = [ pkgs.hello ];
    };

    profile2 = pkgs.buildEnv {
      name = "profile2";
      paths = [ pkgs.coreutils ];
    };
  };
}
