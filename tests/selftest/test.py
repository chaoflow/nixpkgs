"""Selftest of test system
"""
import os
import sys


# make sure plumbum import is working and hello is provided by
# profilePackages
from plumbum.cmd import hello
assert hello() == 'Hello, world!\n'


# check for passed environment variables
assert os.environ['foo'] == "one"
assert os.environ['bar'] == "two"


# check skeleton files
assert open('a').read() == '1'
assert open('b/b').read() == '2'


# look for profile links
assert os.path.islink('profile')
assert os.path.islink('profile1')
assert os.path.islink('profile2')


# test profiles a bit
from plumbum import local

with local.env(**envvars('profile1')):
    assert local['hello']() == 'Hello, world!\n'
    failed = False
    try:
        local['ls']
    except:
        failed = True
    assert failed

with local.env(**envvars('profile2')):
    assert local['ls']
    failed = False
    try:
        local['hello']
    except:
        failed = True
    assert failed

local['false'] & fails("'false' returns non-zero exit code")
local['true'] & succeeds("'true' returns 0 exit code")
local['echo']['Hello, world!'] & succeeds()
