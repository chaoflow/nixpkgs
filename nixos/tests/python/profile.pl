##### Python in system profile, with and without PYTHONPATH

# test modules shipped with python
for my $module ("bsddb", "curses", "curses.panel", "crypt",
                "gdbm", "sqlite3", "ssl", "Tkinter", "readline")
{
    subtest "$python: $module import succeeds", sub {
        # for the wrapped pythonXYFull, we don't need PYTHONPATH
        # to find addon modules shipped with python.
        if ($full) {
            $machine->succeed("$python -c 'import $module'");
        } else {
            $machine->succeed("$PYTHONPATH $python -c 'import $module'");
        }
    };

    # TODO: add minimal functional tests
}


# A module installed into a profile is not seen by a python
# interpreter installed into the same profile, except if
# PYTHONPATH points at it.
subtest "$python: python packages in profile are _not_ available if PYTHONPATH is not set", sub {
    $machine->fail("$python -c 'import flake8'");
    $machine->fail("$python -c 'import nose'");
};

subtest "$python: python packages in profile _are_ available if PYTHONPATH is set to profile", sub {
    $machine->succeed("$PYTHONPATH $python -c 'import flake8'");
    $machine->succeed("$PYTHONPATH $python -c 'import nose'");
};


# A build-time dependency is one that is listed in
# buildInputs, but not put into the pth file, as the package
# does not list it in setup.py install_requires.
subtest "$python: build-time only dependencies are not available", sub {
    $machine->fail("$python -c 'import mock'");        # flake8
};

subtest "$python: run-time dependencies are available", sub {
    $machine->succeed("$PYTHONPATH $python -c 'import mccabe'");    # flake8
    $machine->succeed("$PYTHONPATH $python -c 'import pep8'");      # flake8
    $machine->succeed("$PYTHONPATH $python -c 'import pyflakes'");  # flake8
};

subtest "$python: scripts of installed packages _are_ installed", sub {
    $machine->succeed("test -e /run/current-system/sw/bin/flake8");
    $machine->succeed("test -e /run/current-system/sw/bin/nosetests");
};


# pyflakes is in the install_requires of flake8, coverage is
# only an input of nose, but not a setuptools
# install_requires.
subtest "$python: scripts of dependencies are _not_ installed", sub {
    $machine->fail("test -e /run/current-system/sw/bin/coverage");
    $machine->fail("test -e /run/current-system/sw/bin/pyflakes");
};
