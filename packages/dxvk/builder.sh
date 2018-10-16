source $stdenv/setup

build_dxvk() {
    echo "building ${1}-bit version of DXVK"

    _configure_dxvk $1
    _compile_dxvk $1
    _install_dxvk $1

    echo "finished building ${1}-bit version of DXVK"
}

_configure_dxvk() {
    meson \
        --cross-file build-wine${1}.txt \
        --buildtype release \
        --prefix $PWD/build${1} \
        build.wine${1}
}

_compile_dxvk() {
    cd build.wine${1}
    ninja install
    cd ..
}

_install_dxvk() {
    local lib_dir

    if [ $1 == 64 ]; then
        lib_dir=$out/lib
    else
        lib_dir=$out/lib32
    fi

    mkdir -p $out/bin $lib_dir
    
    cd build${1}
    cp lib/*.dll.so $lib_dir/
    cp bin/setup_dxvk.sh $out/bin/setup_dxvk${1}
    chmod +x $out/bin/setup_dxvk${1}
    cd ..
}