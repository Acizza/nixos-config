{ stdenv,
  fetchurl,
  fetchpatch,
  pkgs,
  wine ? pkgs.wineWowPackages.unstable,
}:

with stdenv.lib;

let
  version = "ce79346";
in
  stdenv.mkDerivation {
    name = "esync-patches-${version}";

    src = fetchurl {
      url = "https://github.com/zfigura/wine/releases/download/esync${version}/esync.tgz";
      sha256 = "0y4sdg9ya399hij1vc9fakhq1sp0091lrsrymzfx7r3vzhmdva62";
    };

    phases = "unpackPhase patchPhase installPhase";

    patches =
      optional (strings.hasInfix "staging" wine.name) (fetchpatch {
          name = "esync-staging-fixes-r3.patch";
          url = "https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-staging-fixes-r3.patch";
          sha256 = "0ckx43jxvkp1wvnmixg870ihj8gdy40f2l96rxa6z6mzq62p7crp";
        })
      ++ optional (versionAtLeast wine.version "3.20") (fetchpatch {
          name = "esync-compat-fixes-r3.patch";
          url = "https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-compat-fixes-r3.patch";
          sha256 = "1sqb46px8qqkx8q0q1b2hqiffxmhi745nd5mf8zswl4ms0y36rds";
        })
      ++ optional (versionAtLeast wine.version "4.4") (fetchpatch {
          name = "esync-compat-fixes-r3.1.patch";
          url = "https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-compat-fixes-r3.1.patch";
          sha256 = "1d18p2ccjvhq0k0i9nik24ik6c0a2fjm5jzbyzvbjzr5qqpcgv0k";
        })
      ++ optional (versionAtLeast wine.version "4.5") (fetchpatch {
          name = "esync-compat-fixes-r3.2.patch";
          url = "https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-compat-fixes-r3.2.patch";
          sha256 = "0nrda0bs069320h4w23nyyyfkzpc5g0s6wn11i52ihz5bjlxyfd0";
        });

    installPhase = ''
        mkdir -p $out/share/esync/
        cp *.patch $out/share/esync/
    '';
  }