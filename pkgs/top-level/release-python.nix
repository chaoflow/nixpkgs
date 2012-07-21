/* A release file for everything that is python or depends on it

   This is used to rework python:
   https://github.com/chaoflow/nixpkgs/tree/python

   A jobset is available at:
   http://hydra.nixos.org/jobset/nixpkgs/python-rework

   Please make sure you set the meta.schedulingPriority of all those
   build to a value < 5 to make sure it has lower priority than any of
   the nixpkgs trunk builds.
   --> this is done in release-lib.nix

   This file will be evaluated by hydra with a call like this:
   hydra_eval_jobs --gc-roots-dir \
     /nix/var/nix/gcroots/per-user/hydra/hydra-roots --argstr \
     system i686-linux --argstr system x86_64-linux --arg \
     nixpkgs "{outPath = ./}" .... release.nix

   Hydra can be installed with "nix-env -i hydra".  */
with (import ./release-lib.nix);

{

  tarball = import ./make-tarball.nix;

} // (mapTestOn (rec {

  gitAndTools = ["x86_64-linux"];
  mesa = ["x86_64-linux"];
  python26 = ["x86_64-linux"];
  python26Full = ["x86_64-linux"];
  python27 = ["x86_64-linux"];
  python27Full = ["x86_64-linux"];
  python27Packages = ["x86_64-linux"];

} ))
