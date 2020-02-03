{ rustPlatform, fetchFromGitHub, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "692b9ed20a1d1388e46f6a994e1d87fa8c905990";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "0j2j5bp5m1xad4hmgw405wdbr1vh39hk6wh870n8l2hh0ssm5d3m";
    };
    
    cargoSha256 = "0cs89k42kjjw6jfx21q1sma2yig4qfckim1xjmf2z7dd6shkdwm5";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev openssl.dev sqlite.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.agpl3;
        platforms = platforms.linux;
    };
}
