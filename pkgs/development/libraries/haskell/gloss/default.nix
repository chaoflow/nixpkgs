{ cabal, bmp, GLUT, OpenGL }:

cabal.mkDerivation (self: {
  pname = "gloss";
  version = "1.7.7.1";
  sha256 = "0g5ik7zv2iywvqingnjvmb9ihk31fwpnjkbfiglzslmga5cjix2a";
  buildDepends = [ bmp GLUT OpenGL ];
  jailbreak = true;
  meta = {
    homepage = "http://gloss.ouroborus.net";
    description = "Painless 2D vector graphics, animations and simulations";
    license = self.stdenv.lib.licenses.mit;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.andres ];
  };
})
