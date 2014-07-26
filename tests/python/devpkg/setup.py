import os
import setuptools

# allow being called from anywhere
os.chdir(os.path.abspath(os.path.dirname(__file__)))

setuptools.setup(
    name='devpkg',
    version='1.0',
    packages=['devpkg'],
    install_requires=['flake8'],
    )
