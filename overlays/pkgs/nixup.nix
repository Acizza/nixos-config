{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "d846c297971ce804c8c79d1002ade75e5bed7181";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "0dsfwccy2sa6r5zks5d4igx4bpcck3mc9vk83fqm8smprsaarsmm";
    };
    
    cargoSha256 = "0bm2rmd6c10f3pjjpd2pz2rjfsijw17czjyrlm0llwjgbvaq4bhk";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
