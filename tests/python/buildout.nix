{ makePythonTest, python26, python27 }:

let
  buildoutTest = makePythonTest ({ buildout, python }: {
    name = "buildout-${buildout.version}-python-${python.version}";
    testFile = ./buildout.py;
    profilePackages =
      [ (python.site {
          name = "test-buildout-${buildout.version}";
          wheels =
            [ buildout
              python.wheels.flake8
              python.wheels.mccabe
              python.wheels.nose
              python.wheels.pep8
              python.wheels.pyflakes
            ];
          scriptsFor = [ buildout ];
        })
      ];
    sources = {
      buildout-project = ./buildout-project;
      devpkg = ./devpkg;
    };
  });

in
{
  buildout17.python26 = buildoutTest rec {
    python = python26;
    buildout = python.wheels.zc_buildout_v1_7;
  };
  buildout17.python27 = buildoutTest rec {
    python = python27;
    buildout = python.wheels.zc_buildout_v1_7;
  };
  buildout22.python26 = buildoutTest rec {
    python = python26;
    buildout = python.wheels.zc_buildout_v2_2;
  };
  buildout22.python27 = buildoutTest rec {
    python = python27;
    buildout = python.wheels.zc_buildout_v2_2;
  };
}
