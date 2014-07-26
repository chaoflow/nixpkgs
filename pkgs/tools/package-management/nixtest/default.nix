{ fetchurl, python2 }:

python2.tool {
  name = "nixtest-0.20140726";
  src = fetchurl {
    url = https://github.com/chaoflow/nixtest/archive/5da403a7936d8fe9aeff23bf3c4c29880b570d24.zip;
    sha256 = "1jbgihfx8726wqiag8zx6g0wc6i1s2x38zwvld5y5b2ik93423wi";
  };
  requires = with python2.wheels; [ click ipdb plumbum ];
  doInstallCheck = true;
  installCheckPhase = "$out/bin/nixtest --help";
}
