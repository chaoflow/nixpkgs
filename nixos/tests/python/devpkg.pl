# A package with dependencies to be installed in develop mode:
# - dateutil depends on six which should be pulled in automatically
# - flake8 depends on pyflakes (among others) which should be auto-pulled
# - ldap has no further dependency
#
# The test runner as well as a cli script need to be able to find all
# dependencies.
#
# Note the difference between the distribution name
# 'python-dateutil' and a package contain within 'dateutil'.
subtest "Create development package:", sub {
    $machine->succeed(
        "mkdir -p devpkg/pkg",
        "echo \"import flake8,pyflakes,dateutil,six,ldap,sys\ndef main():\n  sys.exit(ldap.SCOPE_BASE)\" > devpkg/pkg/__init__.py",
        "echo \"from setuptools import setup; setup(name='devpkg', version='1.0', packages=['pkg'], install_requires=['flake8', 'python-dateutil', 'python-ldap'], entry_points={'console_scripts': ['devpkg=pkg:main']})\" > devpkg/setup.py",
        "echo \"import unittest, pkg\nclass TC(unittest.TestCase):\n  def test_(self):\n    self.assertTrue(pkg)\" > devpkg/pkg/tests.py",
        );
};
