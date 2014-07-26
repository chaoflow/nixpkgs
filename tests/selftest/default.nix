{ makeTest, pkgs }:

makeTest {
  name = "selftest";
  testFile = ./test.py;
  skel = ./skel;

  environment = {
    foo = "one";
    bar = "two";
  };

  profilePackages = [ pkgs.coreutils pkgs.hello ];

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
