##### Preamble

$machine->waitForUnit("multi-user.target");

# map nix to perl variables
my $debug = "@debug@";
my $full = "@full@";
my $python = "@libPrefix@";

# PYTHONPATH set to site-packages of system profile
my $site = "/run/current-system/sw/lib/$python/site-packages";
my $PYTHONPATH = "PYTHONPATH=$site";

# just to show up in the logs and make them easier to identify
subtest "@name@: debug=@debug@, full=@full@, libPrefix=@libPrefix@", sub { };

# if ($debug) {
#     print $machine->succeed("ls -l $site");
#     print $machine->succeed("$python -c 'import sys,pprint;pprint.pprint(sys.path)'");
#     print $machine->succeed("$PYTHONPATH $python -c 'import sys,pprint;pprint.pprint(sys.path)'");
# }
