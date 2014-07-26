"""Buildout tests

Buildout must be able:
- to pick distributions from a nix provided site,
- install a development package that needs these
- create a test runner that finds all of them

"""


buildout = local['buildout']

with local.cwd('buildout-project'):
    buildout['bootstrap'] & succeeds("Bootstrap buildout.")
    buildout['-v'] & succeeds("Run buildout.")

    nose = local['bin/nosetests']
    nose['-w', '../devpkg'] & succeeds("Nose finds test and all packages.")
