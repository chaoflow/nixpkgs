{ makePythonTest, python27, python32, python33, python34  }:

let
  virtualenvTest = makePythonTest ({ python }:
    let
      site = python.site {
        name = "test-virtualenv";
        # XXX: Does not help, virtualenv looks on the very very python
        # Apart from that, we manage without patching virtualenv.
        # I suggest to include ssl with python26, if need be.
        #modules = optional (python.isPy26 or false) python.modules.ssl;
        wheels =
          [ python.wheels.flake8
            python.wheels.mccabe
            python.wheels.nose
            python.wheels.pep8
            python.wheels.pyflakes
            python.wheels.virtualenv
          ];
        scriptsFor = [ python.wheels.virtualenv python.wheels.nose ];
      };

    in
      {
        name = "virtualenv-python-${python.version}";
        testFile = ./virtualenv.py;
        profilePackages = [ site ];
        symlinks = {
          wheelhouse = site.wheelhouse;
        };
        sources = {
          devpkg = ./devpkg;
        };
      }
  );

in
{
  # virtualenv in python26, actually pip can't import HTTPSHandler
  #python26 = virtualenvTest { python = python26; };
  python27 = virtualenvTest { python = python27; };
  python32 = virtualenvTest { python = python32; };
  python33 = virtualenvTest { python = python33; };
  python34 = virtualenvTest { python = python34; };
}