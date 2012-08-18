Enhancing python in nixpkgs and my personal stuff
=================================================

The default branch here is my personal branch, home of this README and
of patches I use, but which I do not consider ready for *real*
publication. It is in the rebase/ namespace so expect it to be rebased
often (see below),

Further there is the py/ namespace with a couple of branches targeting
different aspects of enhancing python packaging within nixpkgs. Here a
full list of branches I consider worth talking about:

- `channel-nixos`_: a manually updated branch reflecting the state of
  the nixos channel, with a delay depending on my activity. This is a
  workaround until hydra maintains such a channel for us. I use it to
  rebase my personal channel onto and merge it regularly into the
  python branch (see below).

- `py/always-unzip`_: always unzip eggs installed into the store, to
  enable easier browsing and tagging of code.

- `py/cleanup`_: cleanup of individual python packages.

- `py/pdb`_: make the python debugger available as a cmdline utility
  ``pdb foo.py``.

- `py/pth-create`_: create pth files for all python packages in any
  inputs as well as preserve easy_install.pth as <name>-<version>.pth.

- `py/pth-recursive`_: python sitecustomize that recursively loads pth
  files.

- `py/extends-packages-and-release-lib`_: extensions to pkgs.lib and
  release-lib, so far only used for py/hydra, but maybe
  polished/sanitized at some point to be merged into master.

- `py/hydra`_: patches only needed for hydra to build the python
  branch and home of this README, not meant to be merged into master
  at any point.

- `python`_: branch suming up python enhancement work and build by
  hydra's python-rework jobset_. This branch does not contain and is
  not supposed to contain any commits, except non-fast-forwarded
  merges of the more specific py/ branches.

- `rebase/personal`_: my personal branch which is frequently rebased.


.. _jobset: http://hydra.nixos.org/jobset/nixpkgs/python-rework

.. _channel-nixos: https://github.com/chaoflow/nixpkgs/tree/channel-nixos

.. _py/always-unzip: https://github.com/chaoflow/nixpkgs/tree/py/always-unzip

.. _py/cleanup: https://github.com/chaoflow/nixpkgs/tree/py/cleanup

.. _py/pdb: https://github.com/chaoflow/nixpkgs/tree/py/pdb

.. _py/pth-create: https://github.com/chaoflow/nixpkgs/tree/py/pth-create

.. _py/pth-recursive: https://github.com/chaoflow/nixpkgs/tree/py/pth-recursive

.. _py/extends-packages-and-release-lib: https://github.com/chaoflow/nixpkgs/tree/py/extends-packages-and-release-lib

.. _python: https://github.com/chaoflow/nixpkgs/tree/python

.. _rebase/personal: https://github.com/chaoflow/nixpkgs/tree/rebase/personal




