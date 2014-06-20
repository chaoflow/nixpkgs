$machine->succeed(
    "mkdir buildout",
    "echo \"[buildout]\ndevelop = ../devpkg\nparts = test py\n[test]\nrecipe = zc.recipe.egg\neggs =\n  nose\n  devpkg\n[py]\nrecipe = zc.recipe.egg\ninterpreter = py\neggs = devpkg\" > buildout/buildout.cfg",
    );

# This sucks!1!!
$machine->succeed("virtualenv -p $python env");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" zc.buildout");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" zc.recipe.egg");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" flake8");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" mccabe");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" pep8");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" pyflakes");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" nose");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" python-dateutil");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" six");
$machine->succeed("$PYTHONPATH ./env/bin/easy_install -H \"\" python-ldap");

$machine->succeed("cd buildout && ../env/bin/buildout -o -v bootstrap");
$machine->succeed("cd buildout && ./bin/buildout -o -v");
$machine->succeed("./buildout/bin/nosetests");
$machine->succeed("./buildout/bin/devpkg");
if ($debug) {
    print $machine->succeed("ls -l buildout/bin");
    print $machine->succeed("./buildout/bin/py -c 'import pprint,sys;pprint.pprint(sys.path)'");
}
