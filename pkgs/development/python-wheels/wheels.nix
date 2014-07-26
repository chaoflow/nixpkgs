
/*
 *  Default set of wheels.
 *
 *  Update manually or use xin
 *
 *  These wheels are build with the build command from wheels-base.nix.
 */

{ callPackage, fetchurl, lib, pkgs }:

python: self: {
  click = {
    name = "click-2.1";
    md5 = "0ba97ba09af82c56e2d35f3412d0aa6e";
  };

  colorama = {
    name = "colorama-0.3.1";
    md5 = "95ce8bf32f5c25adea14b809db3509cb";
  };

  execnet = {
    name = "execnet-1.2.0";
    md5 = "1886d12726b912fc2fd05dfccd7e6432";
  };

  flake8 = {
    name = "flake8-2.2.2";
    md5 = "5489f7dbec86de460839fa4290997040";
  };

  ipdb = {
    name = "ipdb-0.7";
    md5 = "d879f9b2b0f26e0e999809585dcaec61";
  };

  ipdbplugin = {
    name = "ipdbplugin-1.4";
    md5 = "f9a41512e5d901ea0fa199c3f648bba7";
  };

  ipython = {
    disable = python.isPy26 or false;
    name = "ipython-2.0.0";
    sha256 = "0fl9sznx83y2ck8wh5zr8avzjm5hz6r0xz38ij2fil3gin7w10sf";
  };

  # XXX: Probably should live with libxml2
  libxml2 = {
    disable = python.isPy3 or false;
    name = pkgs.libxml2.name;
    src = pkgs.libxml2.src;
    buildInputs = [ pkgs.libiconv pkgs.libxml2 ];
    patchPhase =
      ''
        # we want to change to python subdirectory
        cd python
        sed -i -e "s@^includes_dir = \[@includes_dir = ['${pkgs.libxml2}/include', '${pkgs.libiconv}/include',@" setup.py
      '';
  };

  lxml = {
    disable = python.isPy3 or false;
    name = "lxml-3.3.5";
    md5 = "88c75f4c73fc8f59c9ebb17495044f2f";
    buildInputs = [ pkgs.libxml2 pkgs.libxslt ];
  };

  mccabe = {
    name = "mccabe-0.2.1";
    md5 = "5a3f3fa6a4bad126c88aaaa7dab682f5";
  };

  mock = {
    name = "mock-1.0.1";
    md5 = "c3971991738caa55ec7c356bbc154ee2";
  };

  nose = {
    name = "nose-1.3.3";
    md5 = "42776061bf5206670cb819176dc78654";
  };

  pep8 = {
    name = "pep8-1.5.7";
    md5 = "f6adbdd69365ecca20513c709f9b7c93";
  };

  plumbum = {
    name = "plumbum-1.4.2";
    md5 = "38b526af9012a5282ae91dfe372cefd3";
  };

  py = {
    name = "py-1.4.22";
    md5 = "1af93ed9a00bc38385142ae0eb7cf3ff";
  };

  pyflakes = {
    name = "pyflakes-0.8.1";
    md5 = "905fe91ad14b912807e8fdc2ac2e2c23";
  };

  Pyro3 = {
    name = "Pyro-3.16";
    md5 = "59d4d3f4a8786776c9d7f9051b8f1a69";
  };

  pytest = {
    name = "pytest-2.6.0";
    md5 = "e492f76a986cb9dd0818b7ecc89af92e";
  };

  pytest-cache = {
    name = "pytest-cache-1.0";
    md5 = "e51ff62fec70a1fd456d975ce47977cd";
  };

  pytest-flakes = {
    name = "pytest-flakes-0.2";
    md5 = "44b8f9746fcd827de5c02f14b01728c1";
    format = "zip";
  };

  pytest-pep8 = {
    name = "pytest-pep8-1.0.6";
    md5 = "3debd0bac8f63532ae70c7351e73e993";
  };

  pyx = rec {
    name = "PyX-${if (python.isPy3 or false) then "0.13" else "0.12.1"}";

    src = fetchurl {
      url = "mirror://sourceforge/pyx/${name}.tar.gz";
      sha256 = if (python.isPy3 or false) then
        "1ij23prfvnrarvxck27aiicg9phcc1fbil809bhdh02hjqn9clhr"
      else
        "13kyhqx19rw7dlv2xapdb68j8l9laq6nrpgkyd6549qwidmb4dz8";
    };

    meta = {
      description = ''Python graphics package'';
      longDescription = ''
        PyX is a Python package for the creation of PostScript and PDF
        files. It combines an abstraction of the PostScript drawing
        model with a TeX/LaTeX interface. Complex tasks like 2d and 3d
        plots in publication-ready quality are built out of these
        primitives.
      '';
      license = "GPLv2";
      homepage = http://pyx.sourceforge.net/;
    };
  };

  pyxml = rec {
    disable = python.isPy3 or false;
    name = "PyXML-0.8.4";
    src = fetchurl {
      url = "mirror://sourceforge/pyxml/${name}.tar.gz";
      sha256 = "04wc8i7cdkibhrldy6j65qp5l75zjxf5lx6qxdxfdf2gb3wndawz";
    };
    meta = {
      description = "A collection of libraries to process XML with Python";
      homepage = http://pyxml.sourceforge.net/topics;
    };
  };

  six = {
    name = "six-1.3.0";
    md5 = "ec47fe6070a8a64c802363d2c2b1e2ee";
  };

  unveil = {
    disable = python.isPy26 or false;
    name = "unveil-0.20140726";
    src = fetchurl {
      url = https://github.com/chaoflow/unveil/archive/33cd58263e4fdd863757de7be859fcd538764748.zip;
      sha256 = "08p9nzp9jkhhl136xfyb5drwczg63j1k42vgn3k12bw21dv2p47c";
    };
  };

  virtualenv = {
    name = "virtualenv-1.11.6";
    md5 = "f61cdd983d2c4e6aeabb70b1060d6f49";
  };

  zc_buildout_v1_7 = {
    disable = python.isPy3 or false;
    name = "zc.buildout-1.7.1";
    md5 = "8834a21586bf2be53dc412002241a996";
  };

  zc_buildout_v2_2 = {
    disable = python.isPy3 or false;
    name = "zc.buildout-2.2.1";
    md5 = "476a06eed08506925c700109119b6e41";
  };

  zc_recipe_egg = {
    disable = python.isPy3 or false;
    name = "zc.recipe.egg-2.0.1";
    md5 = "5e81e9d4cc6200f5b1abcf7c653dd9e3";
  };

  zc_recipe_egg_v1 = {
    disable = python.isPy3 or false;
    name = "zc.recipe.egg-1.3.2";
    md5 = "1cb6af73f527490dde461d3614a36475";
  };
}
