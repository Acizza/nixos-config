self: super:

{
  # Proton GE
  # https://github.com/GloriousEggroll/proton-ge-custom
  #
  # Notes for updating:
  #
  # The wine version should match the submodule on the GE repository.
  # 
  # How to update the Proton GE patchset:
  # 1. copy contents of https://github.com/GloriousEggroll/proton-ge-custom/blob/master/patches/protonprep-valve.sh
  #    to the `protonprep` variable
  # 2. remove everything in the `protonprep` variable before the wine patching part
  # 2. move all (or groups of) `git revert` calls in the protonprep script to a new `revert-hashes` file
  # 3. run gen-reverts.sh script
  # 4. copy contents of `generated-reverts` file to the places where the `git reverts` were originally
  wine = ((super.wine.override {
    wineRelease = "unstable";
    wineBuild = "wineWow";

    cupsSupport = false;
    gphoto2Support = false;
    saneSupport = false;
    openclSupport = false;
    gstreamerSupport = false;
    vkd3dSupport = false;
    mingwSupport = true;
  }).overrideAttrs (oldAttrs: rec {
    version = "GE-Proton7-1";

    src = super.fetchFromGitHub {
      name = "source";
      owner = "GloriousEggroll";
      repo = "proton-ge-custom";
      rev = version;
      sha256 = "sha256-aEhDmVG5IchZgT0Eo0UUNWJOn8BimeTBJs8rJKIN/2A=";
    };

    wineSrc = super.fetchFromGitHub {
      owner = "ValveSoftware";
      repo = "wine";
      rev = "8b92bf3aa3d5e9248a2df6c2c27a5ed24a639f0e";
      sha256 = "sha256-BC4+n80SNJhGrh9PWCitQQO3CaxXB4bHaRWJQ8tp31w=";
    };

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    rev = name: sha256: super.fetchurl {
      url = "https://github.com/ValveSoftware/wine/commit/${name}.patch";
      inherit sha256;
    };
  in rec {
    name = "wine-wow-${drv.version}";

    configureFlags = drv.configureFlags or [] ++ [
      "--disable-tests"
    ];

    nativeBuildInputs = drv.nativeBuildInputs ++ [
      super.git
      super.perl
      super.utillinux
      super.autoconf
      super.python3
      super.perl
    ];

    patches = [];

    prePatch =
      let
        vulkanVersion = "1.2.201";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "sha256-ctG+020Te6FXIRli1tWXlcbjK5UHN1RK1AEXlL0VTQU=";
        };
      in ''
        mkdir ge
        mv ./* ./ge || true
        cd ge

        cp -r ${drv.wineSrc}/* ./wine

        chmod +w -R ./wine

        patchShebangs ./wine/tools

        ${protonprep}

        cd wine

        # confirm that Wine's vulkan version matches our set one
        localVulkanVersion=$(grep -oP "VK_XML_VERSION = \"\K(.+?)(?=\")" ./dlls/winevulkan/make_vulkan)

        if [ -z "$localVulkanVersion" ]; then
          echo "error: failed to detect Wine Vulkan version"
          exit 1
        fi

        if [[ "$localVulkanVersion" != "${vulkanVersion}" ]]; then
          echo error: detected Wine vulkan version of $localVulkanVersion
          echo .. currently set vulkan version is ${vulkanVersion}
          exit 1
        fi

        patchShebangs ./dlls/winevulkan/make_vulkan
        patchShebangs ./tools/make_requests

        substituteInPlace ./dlls/winevulkan/make_vulkan --replace \
          "vk_xml = \"vk-{0}.xml\".format(VK_XML_VERSION)" \
          "vk_xml = \"${vkXmlFile}\""

        ./dlls/winevulkan/make_vulkan
        ./tools/make_requests
        autoreconf -f

        # move wine source back to base directory
        mv ./* ../../
        cd ../../
        rm -r ge/
      '';

    protonprep = super.writeShellScript "protonprep.sh" ''
      ### (2) WINE PATCHING ###

          cd wine
          git reset --hard HEAD
          git clean -xdf

      ### (2-1) PROBLEMATIC COMMIT REVERT SECTION ###

        patch -RNp1 < ${rev "e618790bd251b618c60a9ad9eda0b55d89c039c5" "17mdk0fb30q2vdff14g6ljlyblhwqwfg2g6v74d008bdvwkrvm0q"}
        patch -RNp1 < ${rev "48eb121da0c510d5dd4be8032142fc1d748dfb4c" "0mpf444i968azsk72r35ig9f0c3llkyiv87xikf3ivg6qmada8by"}
        patch -RNp1 < ${rev "d40d8449e6aee3075493ead78e2b0e0f81687ab1" "1w10h87fb5y9pmwkk4g5flara1am3bzapqcrmxzvkp61nnxg7bal"}
        patch -RNp1 < ${rev "399959ab38d527855f3bbeb77ba1d5ee086c9034" "0217pmpkfwcfjbj59i8841wjzv8vmva6agvyx7fc2smhhgaha5cp"}
        patch -RNp1 < ${rev "5a4c148d9db3ea09c24cba1d1fe269062361fd71" "1fpb245waqrspwm0f02hxaw28k83ji2qc4yj3x9427zszf41vyb1"}
        patch -RNp1 < ${rev "114a59ade064be1a7ed945a337c6e53f9d4b8fa1" "0lm34rpn96bz6fjbrrrs8irm4ac3ds27m9pp7ykim998v48xk50x"}
        patch -RNp1 < ${rev "e7416adb3cec32d25203f85c44efd5a428de9790" "0yywq0aff3vqq27fmz4rqawnx54cwb9rrqxds344rlpmfaq4k8xc"}
        patch -RNp1 < ${rev "299b4da83472613bf62ef2771817376afef293a5" "08ibgd8pq5jqb7zwcdr0ph1rssbnllzwyhg7l4akf2ac7g9zvfsd"}
        patch -RNp1 < ${rev "e147ff28c45df00255c0d95f0888f845c4d1e9ec" "17dii8nwg0bdvvnjg377f26jybc2w5f2lxs5kyqch1g0p1s2rbyk"}
        patch -RNp1 < ${rev "82dab2b800531323d3cecd1524f1fd3ceba47e56" "10j9vk6a5rlr1hadr9mwa2arl14is5g1wssmw0njn8qi6vajwqjc"}
        patch -RNp1 < ${rev "3ba555fe450a548c4671c64aa71834540c0a6393" "1ylijw2a4z46982g9m8y77lvd1gamdm5nqcgnnfcqcp8zc9q93bv"}
        patch -RNp1 < ${rev "b8b34e1ba40a7a76717678af4e8688fc6d0bc94c" "08fkil0rpf3jkk9b5fhnb49gc4aph5jw3l5jh3wirn3z7f1dzrb3"}
        patch -RNp1 < ${rev "cf616561fb6679f72080946cdd41dba71f66a163" "0wxa5v7hwwg4i0zalpvad2lw8946qi5q49z0la8r03pagzp52v0m"}
        patch -RNp1 < ${rev "2ddae281174f84d0f1de0e00de94461bbb6db5a7" "001y0awagd724bd62f48nig2563rdlc6hr10wvk6md4zjwc9a602"}
        patch -RNp1 < ${rev "d70867c354637e5d6edb25d124e08668b748cd4d" "1bdj6dla3kzrx36csbclrglxzsj10njp5ysk819q9rvf7h2n2j3a"}
        patch -RNp1 < ${rev "c70e9a2b6c980f8ed7234ee35dccd296fa4bf80b" "1lf8dpxszfrnkgl4vhqifgz25ggbf1rwpnhzhp8v89m92ags6dj9"}
        patch -RNp1 < ${rev "c245738adf4d222204b243e17bee025db73865ff" "0wrjn8xg1hvipzqxrgjv9rprdmf1wbj1aawxfgimji8dl0imbbj5"}
        patch -RNp1 < ${rev "e7388cd4b832fc9ba64640c61b2786244b349e25" "1752ba19ykk31h7lkdyjmvc5sxn070d4hl3hs1gyz7x8wyxpsg0r"}
        patch -RNp1 < ${rev "3ffb90f5160b3141aed29355488dbf054c60a293" "1hwp4c5ifgh45wjg55c5n4cz6sw0jfsnzf6jn2g66ck92hizi6z3"}
        patch -RNp1 < ${rev "f4a00970ee56b3cbf4cee88d592f984ba9ae2799" "1s285a8bv36m93xx31zgg52qj2bw0r0704fqph21ik4mga0gdqd5"}
        patch -RNp1 < ${rev "fbf46aeef3db5b3a9a58441ab6fd62501c183afb" "1h1k9ymb7fgg2bn3sn4gzhafh8c05a5fr0h2j34q4jbj2wgrhxql"}
        patch -RNp1 < ${rev "e55e47086014d7a7be94da17b4be7cf312e8ad80" "09bp7d62mf83dpqjhc4wy5dlmx8g8i4hmw7i5rha0dgcvqpq37mx"}
        patch -RNp1 < ${rev "90c099fcb690675226493994c445df025ad00076" "0l70i2l7bwcg4bml4x66131n4w1zw36bpqdn5cbw8c4hjjlqxx8s"}
        patch -RNp1 < ${rev "04f8b7983e914e9b005a7f99bd2b1bd2f908b0ab" "0rs25dpr9hrhbibq0hs3klsisjjxdqdalhkip6h3kxnvb25lvi5m"}
        patch -RNp1 < ${rev "3b2e609842ff793db7a78034d5465b4c0449d54d" "1qnvxzhd61yh28sd4y60anwbfrf9i7r01p5s7g3z990s8nm6yyfv"}
        patch -RNp1 < ${rev "18f6b86622e0ff11cc540c842a5727226742bbfc" "0ranjij31jxp4mf0920rvmbzxidbmjv9qdzwklh7591wypn8ny7d"}
        patch -RNp1 < ${rev "337006b72fc819575fb188c6f5543d27c4c6b7eb" "14adihg2ll2s1fn5b5kkij5n9h41kqfmf5gl836hap547kv2gdnr"}
        patch -RNp1 < ${rev "7ec3158fe73bbe005f18c67f4c2c6c0f9dd14334" "1bpl75q8pp2xwxs7j2y9dqlllvywdznynbfh903g10jz68yjxvp3"}
        patch -RNp1 < ${rev "3a8f3099c3088470afe8329c85854874416b6f2b" "0la0fww6i3xaigmhf86wr25bmg2hp9h6406j2vfixg1jcccgl2aw"}
        patch -RNp1 < ${rev "ab73f4b93b7149b5e44587d7f0572b02c349cef2" "14sm8xq7bj5y3z9mf11wbw4kvybl1c2hwkhnw19fs66iwsbx80l0"}
        patch -RNp1 < ${rev "f132c9755b5a5ddf44cfff0c2fa135d74630653d" "0ls52j16hn7kk58h8rkksxkh5rv9dfq7v9w61kqq36j0433zqzp8"}
        patch -RNp1 < ${rev "d83e51a825ff660588c81568b161cfe2c5039544" "0wgsnq15ksr67mrfbzaqqf9wj1h0nr9c8lzbgsr46kmcsb5qd5mm"}
        patch -RNp1 < ${rev "03f070df796ae1e716f7972065ea64890754a33d" "05hl7mcnr9h55xaf6a82rddmax43fkjifqxxl4cmc4z18bnbmqly"}
        patch -RNp1 < ${rev "333b74ffb43116041897c46bf3eca00e536101b4" "09f5rfvg1i6arigd1hdmq9izqfc12260jmgwdas3z4zfj9cn4z84"}
        patch -RNp1 < ${rev "12d8e04ac3ec49e4cf6ba564acd84ebe070d3c8b" "1bciwxc069l84caf6ch08qgpkj2kffavngnfwazl2a5bl5zvi99a"}
        patch -RNp1 < ${rev "0f9406c32e9bf1c9e3144bc065ef0ef92f5b3dfe" "1grqsmz5pwy2bb7hkwk7c03vs70zknhpkd65wrkj32hjvr86y3pc"}
        patch -RNp1 < ${rev "b78092616d59a45255ab3d96671b4cab94714f7d" "13k0zfgij4flc01xq7bgl8kiy5s62qd6n8ghzxxxw0q4dxihi6xk"}
        patch -RNp1 < ${rev "74d85e35206c485a585db5cfd06b65d08ed1a31d" "13n5gxa353269p350xxwljf0mbny3l3vcya8rrzxvicb84jajp19"}
        patch -RNp1 < ${rev "e481733c0445889989595659604031051507ad2c" "1afiv8d84svi1xwp0g6ia9c2d20nvvhs9756jvg2lrinx5pd6sd6"}
        patch -RNp1 < ${rev "00334a596ecd3446218b278458466b28811fb985" "0z2avazai4ipcsnxz3xciyldl746w1ra863cxw2xa92h0xxvgifc"}
        patch -RNp1 < ${rev "2437dbb72b1bf90ccb2030632d59f6df7d34023d" "0dfbjwfv4l629l066jmw9gkmrxlpfxzm7x5nn8p77y7gq7j8dffj"}
        patch -RNp1 < ${rev "cf102b990f510e6a94497bca9504929379db1d20" "0i0k0yxcvxxgjmv06ckwnr2bs11k8irgwfw0yn5jbpiyxcw934nb"}
        patch -RNp1 < ${rev "5c272d20d8c42c82438a926ccdc802aca6a4f416" "0jv467zpr8fx53ah2zy8vf5c3d6pbfqfpwcw5aj9mxcm4y6s4k0i"}
        patch -RNp1 < ${rev "1beb998df6007991345072dc64e498fb47a75681" "02d6wq294v6lnnkzayld3rs70af9q1b580szzfsawfmjs2gg60vy"}
        patch -RNp1 < ${rev "1cecbf6fb95e692cef118bc3ca8ffff1df73acd9" "17p7gwzjaqmsyawcb2x85lksz4qc28vs48k9ji25vdaxspdyyv7s"}
        patch -RNp1 < ${rev "bac2d8dc0ea2078247300cb039d151b9ac78dacd" "1s6cjdssy17y9bkxyqn5lbdif7zmbs1i8gk36cmw0xg63rcm0nf4"}
        patch -RNp1 < ${rev "1b3784db60e3c9dcd439176920f60954321818cd" "1v69a9zwx97mwimj172glmg0219pzg7j0hzlnxzrpldnkwspawdl"}
        patch -RNp1 < ${rev "7d84e9903242255ed60e6a68c927ecff42bd41ef" "0nhz46zg7w6lq86c5i1l1g4f4ywxyyf2vdxq4w03ddcdbzh6w8zq"}
        patch -RNp1 < ${rev "7d6cc8a89a114ee37f1d0cbae1a620d77d4c5f17" "0rwy9qxg6a6fb6yvls1aic49jws1g7n7csqv0ck4f6r0dj7yjhkj"}
        patch -RNp1 < ${rev "066e553ae98beefb05e12099e2b071eac929417c" "0ag7g6kp3y4nqm9wwiz3d2cmm4vknkcacq0wmcrx73py6kgw7zw8"}
        patch -RNp1 < ${rev "ff2df069b859c9f2572619946bb7b8275f1eb33f" "1jmbkjik5w7xmqfapnk982mv69pxnizafpzs9a5knii3ndmz323h"}
        patch -RNp1 < ${rev "6e6760c8a06368dc0a0de69ea061318fe88edcf7" "0rzc6ivvchb3ywap964q8cnmbyhc7zd7dm5as58j2yvqd7cgfsl6"}
        patch -RNp1 < ${rev "18134858af0b791774aef8bba34961f1b3cd1158" "0xhn891g6q835x0p8macw01f3vhxvs3nq4pmsf29vmjm34phja3b"}



      ### END PROBLEMATIC COMMIT REVERT SECTION ###


      ### (2-2) WINE STAGING APPLY SECTION ###

          # We manually apply this because reverting it in staging is being a pain in the ass despite it being just 4 lines.
          # -W stdole32.tlb-SLTG_Typelib \

          # these cause window freezes/hangs with origin
          # -W winex11-_NET_ACTIVE_WINDOW \
          # -W winex11-WM_WINDOWPOSCHANGING \

          # this interferes with fshack
          #-W winex11-MWM_Decorations \

          # this interferes with protons keyboard translation patches
          #-W winex11-key_translation \

          # ntdll-Junction_Points breaks Valve's CEG drm
          # the other two rely on it.
          # note: we also have to manually remove the ntdll-Junction_Points patchset from esync in staging.
          # we also disable esync and apply it manually instead
          # -W ntdll-Junction_Points \
          # -W server-File_Permissions \
          # -W server-Stored_ACLs \
          # -W eventfd_synchronization \

          # Sancreed — 11/21/2021
          # Heads up, it appears that a bunch of Ubisoft Connect games (3/3 I had installed and could test) will crash
          # almost immediately on newer Wine Staging/TKG inside pe_load_debug_info function unless the dbghelp-Debug_Symbols staging # patchset is disabled.
          # -W dbghelp-Debug_Symbols \

      ### END WINE STAGING APPLY SECTION ###

      ### (2-3) GAME PATCH SECTION ###

          echo "WINE: -GAME FIXES- mech warrior online fix"
          patch -Np1 < ../patches/game-patches/mwo.patch

          echo "WINE: -GAME FIXES- assetto corsa hud fix"
          patch -Np1 < ../patches/game-patches/assettocorsa-hud.patch

          echo "WINE: -GAME FIXES- mk11 crash fix"
          # this is needed so that online multi-player does not crash
          patch -Np1 < ../patches/game-patches/mk11.patch

          echo "WINE: -GAME FIXES- killer instinct vulkan fix"
          patch -Np1 < ../patches/game-patches/killer-instinct-winevulkan_fix.patch

          echo "WINE: -GAME FIXES- Castlevania Advance fix"
          patch -Np1 < ../patches/game-patches/castlevania-advance-collection.patch

          echo "WINE: -GAME FIXES- add cities XXL patches"
          patch -Np1 < ../patches/game-patches/v5-0001-windowscodecs-Correctly-handle-8bpp-custom-conver.patch

      ### END GAME PATCH SECTION ###

      ### (2-4) PROTON PATCH SECTION ###

          echo "WINE: -PROTON- fullscreen hack fsr patch"
          patch -Np1 < ../patches/proton/48-proton-fshack_amd_fsr.patch

          echo "WINE: -PROTON- fake current res patches"
          patch -Np1 < ../patches/proton/65-proton-fake_current_res_patches.patch

      ### END PROTON PATCH SECTION ###

      ### START MFPLAT PATCH SECTION ###

          echo "WINE: -MFPLAT- mfplat patches"
          patch -Np1 < ../patches/proton/31-proton-mfplat-patches-valve.patch

          # missing http: scheme workaround see: https://github.com/ValveSoftware/Proton/issues/5195
      #    echo "WINE: -MFPLAT- The Good Life (1452500) workaround"
      #    patch -Np1 < ../patches/wine-hotfixes/mfplat/thegoodlife-mfplat-http-scheme-workaround.patch

          # Needed for godfall intro
      #    echo "mfplat godfall fix"
      #    patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-godfall-hotfix.patch


      ### END MFPLAT PATCH SECTION ###





      ### (2-5) WINE HOTFIX SECTION ###

          # https://github.com/Frogging-Family/wine-tkg-git/commit/ca0daac62037be72ae5dd7bf87c705c989eba2cb
          echo "WINE: -HOTFIX- unity crash hotfix"
          patch -Np1 < ../patches/wine-hotfixes/pending/unity_crash_hotfix.patch

      #    disabled, not compatible with fshack, not compatible with fsr, missing dependencies inside proton.
      #    patch -Np1 < ../patches/wine-hotfixes/testing/wine_wayland_driver.patch

      #    # https://bugs.winehq.org/show_bug.cgi?id=51687
      #    patch -Np1 < ../patches/wine-hotfixes/pending/Return_nt_filename_and_resolve_DOS_drive_path.patch

      ### END WINE HOTFIX SECTION ###
    '';
  });
}