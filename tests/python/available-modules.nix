{ lib, makePythonTest
, python26Full, python27Full
, python26, python27, python32, python33, python34
}:

let
  availableModulesTest = makePythonTest ({ modules ? [], failModules ? [], python }: {
    name = "availableModules-${python.name}";
    testFile = ./available-modules.py;
    profilePackages = [ python ];
    environment = {
      TEST_PYTHON_MODULES = lib.concatStringsSep " " modules;
      TEST_PYTHON_FAIL_MODULES = lib.concatStringsSep " " failModules;
    };
  });

in
{
  python26 = availableModulesTest {
    python = python26;
    failModules =
      [ "bsddb"
        "curses"
        "curses.panel"
        #"crypt"
        "gdbm"
        "sqlite3"
        "ssl"
        "Tkinter"
        "readline"
      ];
  };
  python26Full = availableModulesTest {
    python = python26Full;
    modules =
      [ "bsddb"
        "curses"
        "curses.panel"
        "crypt"
        "gdbm"
        "sqlite3"
        "ssl"
        "Tkinter"
        "readline"
      ];
  };
  python27 = availableModulesTest {
    python = python27;
    failModules =
      [ "bsddb"
        "curses"
        "curses.panel"
        #"crypt"
        "gdbm"
        "sqlite3"
        #"ssl"
        "Tkinter"
        "readline"
      ];
  };
  python27Full = availableModulesTest {
    python = python27Full;
    modules =
      [ "bsddb"
        "curses"
        "curses.panel"
        "crypt"
        "gdbm"
        "sqlite3"
        "ssl"
        "Tkinter"
        "readline"
      ];
  };
  python32 = availableModulesTest {
    python = python32;
    modules =
      [ #"bsddb"
        "curses"
        "curses.panel"
        "crypt"
        #"gdbm"
        "sqlite3"
        "ssl"
        #"Tkinter"
        "readline"
      ];
  };
  python33 = availableModulesTest {
    python = python33;
    modules =
      [ #"bsddb"
        "curses"
        "curses.panel"
        "crypt"
        #"gdbm"
        "sqlite3"
        "ssl"
        #"Tkinter"
        "readline"
      ];
  };
  python34 = availableModulesTest {
    python = python34;
    modules =
      [ #"bsddb"
        "curses"
        "curses.panel"
        "crypt"
        #"gdbm"
        "sqlite3"
        "ssl"
        #"Tkinter"
        "readline"
      ];
  };
}
