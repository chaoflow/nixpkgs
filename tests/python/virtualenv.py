"""Virtualenv test
"""

virtualenv = local['virtualenv']

virtualenv['isolated'] & succeeds('Create isolated virtualenv.')
with local.cwd('isolated'):
    py = local['bin/python']

    py['-c', 'import flake8'] \
        & fails("Virtualenv _is_ isolated.")

    py['../devpkg/setup.py', 'develop', '-H""'] \
        & fails("Dependencies are missing.")

    pip = local['./bin/pip']
    pip['install',
        '--use-wheel',
        '--no-index',
        '--find-links', '../wheelhouse',
        'flake8'] \
        & succeeds('Install flake8 from wheelhouse')

    py['-c', 'import flake8'] \
        & succeeds("Flake8 is found now.")

    py['../devpkg/setup.py', 'develop', '-H""'] \
        & succeeds("Dependencies are now available.")

    pip['install',
        '--use-wheel',
        '--no-index',
        '--find-links', '../wheelhouse',
        'nose'] \
        & succeeds('Install nose from wheelhouse')
    nose = local['./bin/nosetests']
    nose['-w', '../devpkg'] \
        & succeeds("Nose finds devpkg and its dependencies")


virtualenv['--system-site-packages', 'env'] & succeeds('Create virtualenv.')
with local.cwd('env'):
    py = local['bin/python']

    py['-c', 'import flake8'] \
        & succeeds("Virtualenv is _not_ isolated.")

    py['../devpkg/setup.py', 'develop'] \
        & succeeds("Dependencies are available.")

    # XXX: There seems to be no way to get the nosetests script
    # locally using pip, as nose is already installed in the
    # "system-site-packages"
    pip['install',
        '--use-wheel',
        '--no-index',
        '--find-links', '../wheelhouse',
        '--upgrade',
        'nose'] \
        & succeeds('Install nose from wheelhouse')
    nose = local['./bin/nosetests']

    # Because of nose magic, for our limited test case, we can use the
    # "global" nosetests. However, this would not find further
    # dependencies installed in the virtualenv, only the devpkg, we
    # are pointing it at directly.
    nose = local['nosetests']
    nose['-w', '../devpkg'] \
        & succeeds("Nose finds devpkg and its dependencies")
