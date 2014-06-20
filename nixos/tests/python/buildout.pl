$machine->succeed(
    "mkdir buildout",
    "echo \"[buildout]\ndevelop = ../devpkg\nparts = test py\n[test]\nrecipe = zc.recipe.egg\neggs =\n  nose\n  devpkg\n[py]\nrecipe = zc.recipe.egg\ninterpreter = py\neggs = devpkg\" > buildout/buildout.cfg",
    );

$machine->succeed("cd buildout && buildout -o -v bootstrap");
$machine->succeed("cd buildout && $PYTHONPATH ./bin/buildout -o -v");
$machine->succeed("./buildout/bin/nosetests");
$machine->succeed("./buildout/bin/devpkg");
if ($debug) {
    print $machine->succeed("ls -l buildout/bin");
    print $machine->succeed("./buildout/bin/py -c 'import pprint,sys;pprint.pprint(sys.path)'");
}
