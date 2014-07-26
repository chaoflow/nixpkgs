### This file will be generated and is recursively merged under wheels
python: self:
{
  grako.requires = [];
  ipdb.requires = [ self.ipython ];
  plumbum.requires = [ self.six ];
  pytest.requires = [ self.py ];
  pytest-cache.requires = [ self.execnet ];
  pytest-flakes.requires = [ self.pytest-cache self.pyflakes ];
  pytest-pep8.requires = [ self.pytest-cache self.pep8 ];
  unveil.requires = [ self.click ];
  zc_buildout_v1_7.requires = [ self.setuptools self.zc_recipe_egg_v1 ];
  zc_buildout_v2_2.requires = [ self.setuptools self.zc_recipe_egg ];
}