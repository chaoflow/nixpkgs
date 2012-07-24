/*
  This file will be evaluated by hydra with a call like this:
  hydra_eval_jobs --gc-roots-dir \
    /nix/var/nix/gcroots/per-user/hydra/hydra-roots --argstr \
    system i686-linux --argstr system x86_64-linux --arg \
    nixpkgs "{outPath = ./}" .... release.nix

  Hydra can be installed with "nix-env -i hydra".
*/
with (import ./release-lib.nix);

{

  tarball = import ./make-tarball.nix;

} // (mapTestOn
  (condPackagesWithMetaPlatform
     ["x86_64-linux"]
     (dependsOnOrIs [pkgs.python26 pkgs.python27])
     { abc = pkgs.python27Full; } ))

