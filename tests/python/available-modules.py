"""Test full python

In nix ``pkgs.pythonFull`` is python with all addon modules that ship
with python, whereas ``pkgs.python`` does not contain certain modules.

This test ensures that an installed python interpreter has all these
modules available.

"""
import os

from plumbum import FG


EXE = os.environ['TEST_PYTHON_EXECUTABLE']
MODULES = os.environ['TEST_PYTHON_MODULES']
FAIL_MODULES = os.environ['TEST_PYTHON_FAIL_MODULES']

py = local[EXE]['-c']

for x in MODULES.split():
    py['import %s' % x] & succeeds("%s available for import" % x)

for x in FAIL_MODULES.split():
    py['import %s' % x] & fails("%s must not be available for import" % x)
