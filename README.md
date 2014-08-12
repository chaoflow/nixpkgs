The python branch is home of wheel-based [python
packaging](./pkgs/development/python-wheels/) and experimental
[nixpkgs testing](./tests) using
[nixtest](https://github.com/chaoflow/nixtest) as test driver.

This branch is not meant to be merged into master and expected to
experience rebasing. There will be specific pull requests once things
stabilize.

Hydra builds this branch as the
[python-rework](http://hydra.nixos.org/jobset/nixpkgs/python-rework)
jobset.

To make use of these hydra builds, subscribe to the channel:

  % nix-channel --add http://hydra.nixos.org/jobset/nixpkgs/python-rework/channel/latest python-rework
  % nix-channel --update