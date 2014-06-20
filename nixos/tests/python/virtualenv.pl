##### Using virtualenv to develop on a package

subtest "virtualenv: initialises $python", sub {
    $machine->succeed("virtualenv -p $python env");
    $machine->succeed("./env/bin/python -c 'import sys; sys.exit({True: 0, False: 1}[\"python\" + sys.version[:3] == \"$python\"])'");
    $machine->succeed("./env/bin/python -c 'import sys,pprint;pprint.pprint(sys.path)'");
};

# A virtualenv per se is isolated
subtest "$python virtualenv: easy_install fails to install unavailable package", sub {
    $machine->fail("./env/bin/easy_install -H \"\" flake8");
};


# connect virtualenv to profil
subtest "$python virtualenv: make profile site visible to virtualenv", sub {
    $machine->succeed("echo $site > env/lib/$python/site-packages/nixprofile.pth");
    if ($debug) {
        print "FFFFFFFFFFFFFF";
        print $machine->succeed("./env/bin/python -c 'import sys,pprint;pprint.pprint(sys.path)'");
    }
    $machine->succeed("./env/bin/easy_install -H \"\" flake8");
};

# easy_install adds the package itself to pth, but not its
# dependencies. chaoflow would like the dependencies to be
# also added to pth, but still no scripts created for
# dependencies.
#
# This means, with that easy_install hack, we get scripts,
# which also see the virtualenv, but we need to keep
# PYTHONPATH. That's cool!
subtest "$python virtualenv: easy_install with PYTHONPATH", sub {
    $machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" flake8");
    $machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" nose");
    if ($debug) {
        print "\n\n$python virtualenv after easy_install:\n";
        print $machine->succeed("cat ./env/lib/$python/site-packages/easy-install.pth");
        print $machine->succeed("ls -l ./env/bin");
    }
};

subtest "$python virtualenv: scripts for package but not for dependencies", sub {
    $machine->succeed("test -e ./env/bin/nosetests");
    $machine->succeed("test -e ./env/bin/flake8");
    $machine->fail("test -e ./env/bin/pyflakes");
};


# PYTHONPATH needs to be set for the venv scripts to see the
# profile. It would be totally cool, if this would not be
# the case.
subtest "$python virtualenv: PYTHONPATH needed to run previously installed script", sub {
    $machine->fail("./env/bin/flake8 --version");
    $machine->succeed("$PYTHONPATH ./env/bin/flake8 --version");
};


# python setup.py develop adds the package and all
# dependencies to pth and also creates scripts for all of
# them. It would not be bad, if it would not create scripts
# for all dependencies.
subtest "$python virtualenv: develop package with dependency from profile", sub {
    $machine->succeed("cd devpkg && $PYTHONPATH ../env/bin/python setup.py develop -H \"\"");
    #print "\n\n$python virtualenv after develop install:\n";
    #print $machine->succeed("cat ./env/lib/$python/site-packages/easy-install.pth");
    #print $machine->succeed("ls -l ./env/bin");
};


# PYTHONPATH is not needed as develop put all deps into
# pth. This is actually pretty nice.
subtest "$python virtualenv: develop package testrunner and script work without PYTHONPATH.", sub {
    $machine->succeed("./env/bin/nosetests devpkg");
    $machine->succeed("./env/bin/devpkg");
};
