self: super:

{
  # Proton GE
  # https://github.com/GloriousEggroll/proton-ge-custom
  #
  # Notes for updating:
  #
  # The wine and wine-staging versions should match the submodules on the GE repository.
  # 
  # How to update the Proton GE patchset:
  # 1. copy contents of https://github.com/GloriousEggroll/proton-ge-custom/blob/master/patches/protonprep.sh
  #    to the `protonprep` variable
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
    gsmSupport = false;
    gstreamerSupport = false;
    vkd3dSupport = false;
    mingwSupport = true;
  }).overrideAttrs (oldAttrs: rec {
    version = "6.21";

    protonGeVersion = "GE-1";

    fullVersion = "${version}-${protonGeVersion}";

    src = super.fetchFromGitHub {
      name = "source";
      owner = "GloriousEggroll";
      repo = "proton-ge-custom";
      rev = "${version}-${protonGeVersion}";
      sha256 = "BTw8hAqyfb3pcbv6+9C8ELxR37wZ4QSJo7hgSdsLAKQ=";
    };

    wineSrc = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      #rev = "wine-${version}";
      rev = "be0684dad50ffbc93b3ded4fbfebf1d1e4690589";
      sha256 = "i2JD/aHYfF0Gt3LmSdfGTHNRuqAxqFOoZ9S2XvltC+s=";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      #rev = "v${version}";
      rev = "a9aa06c58eea77c66417b48669a00d7b32b70c99";
      sha256 = "SsIpSltmcfdaGl0rVV4zykWsJPMZSgTrw5KVlEpJ88s=";
    };

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    rev = name: sha256: super.fetchurl {
      url = "https://github.com/wine-mirror/wine/commit/${name}.patch";
      inherit sha256;
    };

    revStaging = name: sha256: super.fetchurl {
      url = "https://github.com/wine-staging/wine-staging/commit/${name}.patch";
      inherit sha256;
    };
  in rec {
    name = "wine-wow-${drv.version}-staging";

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
        vulkanVersion = "1.2.197";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "YCm1r71NWAjLG2wnq+4x1vOcHozJmnrf9uOB7375KRQ=";
        };
      in ''
        mkdir ge
        mv ./* ./ge || true
        cd ge

        cp -r ${drv.wineSrc}/* ./wine
        cp -r ${drv.staging}/* ./wine-staging

        chmod +w -R ./wine
        chmod +w -R ./wine-staging

        patchShebangs ./wine/tools
        patchShebangs ./wine-staging/patches/gitapply.sh

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
      ### (1) PREP SECTION ###

          #WINE STAGING
          cd wine-staging

          # revert pending pulseaudio changes
          patch -RNp1 < ${(revStaging "183fd3e089b170d5b7405a80a23e81dc7c4dd682" "KSt+CmEK3ghyOVyIeRFbCFoXLyYEJH4AL0y78lfcnJk=")}

          # reenable pulseaudio patches
          patch -Np1 < ../patches/wine-hotfixes/staging/x3daudio_staging_revert.patch
          patch -Np1 < ../patches/wine-hotfixes/staging/staging-reenable-pulse.patch
          patch -RNp1 < ../patches/wine-hotfixes/staging/staging-pulseaudio-reverts.patch

          # add proton-specific syscall emulation patches
          patch -Np1 < ../patches/wine-hotfixes/staging/proton-staging-syscall-emu.patch

          # allow esync patches to apply without depending on ntdll-Junction_Points
          patch -Np1 < ../patches/wine-hotfixes/staging/staging-esync_remove_ntdll_Junction_Points_dependency.patch

          cd ..

      ### END PREP SECTION ###

      ### (2) WINE PATCHING ###

          cd wine

      ### (2-1) PROBLEMATIC COMMIT REVERT SECTION ###

          # https://github.com/ValveSoftware/Proton/issues/1295#issuecomment-859185208
          echo "these break Tokyo Xanadu Xe+"
          patch -RNp1 < ${rev "2ad44002da683634de768dbe49a0ba09c5f26f08" "0pd5n660jfkad453w8aqcffpz2k7575z20g948846bkjff7mq7xv"} || true
          patch -RNp1 < ${rev "dfa4c07941322dbcad54507cd0acf271a6c719ab" "0k2hgffzhjavrpxhiddirs2yghy769k61s6qmz1a6g3kamg92a0s"} || true

          # https://bugs.winehq.org/show_bug.cgi?id=49990
          echo "revert bd27af974a21085cd0dc78b37b715bbcc3cfab69 which breaks some game launchers and 3D Mark"
          patch -RNp1 < ${(rev "b54199101fd307199c481709d4b1358ba4bcce58" "5YCcgc/YslwbO4x+nRTn/sJFQMWk9U/KdmZ/laz+OHY=")}
          patch -RNp1 < ${(rev "dedda40e5d7b5a3bcf67eea95145810da283d7d9" "/Aub+Bt3QTgC2lJlSTFCZRdXeEQatX8tsfX8Omyj3BQ=")}
          patch -RNp1 < ${(rev "bd27af974a21085cd0dc78b37b715bbcc3cfab69" "FU7Zh9LKZFfrxhlaq3NssGDpXUizKW7VoyRwF6y5Eag=")}

          echo "revert faudio updates -- we can't use PE version yet because the staging patches need a rebase in order to fix audio crackling in some games -- notably cyberpunk"
          patch -RNp1 < ${(rev "22c26a2dde318b5b370fc269cab871e5a8bc4231" "tCMBv9dcqo0zr8MWgb6ebISBCyDvV3VVkUYquOG6ius=")}

          echo "mfplat early reverts to re-enable staging mfplat patches"
          patch -RNp1 < ${rev "747905c674d521b61923a6cff1d630c85a74d065" "09l1dy0phvcgi1dci4lxnai5gcr09wr91mzw85afhd7zhnyy2y79"}
          patch -RNp1 < ${rev "f3624e2d642c4f5c1042d24a70273db4437fcef9" "0lxy46hfnimdsracgy4sjm6a4zp6hmvbnccgyvavf2fliknj93gh"}
          patch -RNp1 < ${rev "769057b9b281eaaba7ee438dedb7f922b0903472" "1i3mfj38k1bairafqnw44j285vqkkbf8fa204rn50w2y2caylvvw"}
          patch -RNp1 < ${rev "639c04a5b4e1ffd1d8328f60af998185a04d0c50" "1fc52k5fpmm2d3agzzfvybyvy7z76gsjckdvcigmm659pwd94gs2"}
          patch -RNp1 < ${rev "54f825d237c1dcb0774fd3e3f4cfafb7c243aab5" "051x6igwwjic20c1p04526yrb23h2ab40mh1s8m7661jqala8734"}
          patch -RNp1 < ${rev "cad38401bf091917396b24ad9c92091760cc696f" "1lp2kxc3ca4qs2snslayw2x57q4gdkbs10ybb3919vbzwmhjhhbx"}
          patch -RNp1 < ${rev "894e0712459ec2d48b1298724776134d2a966f66" "0g4y5b927ijsl912yqjzzdv3qigz6j4lc3mbjcdcffkmpwd1f6kj"}
          patch -RNp1 < ${rev "42da77bbcfeae16b5f138ad3f2a3e3030ae0844b" "0j7fbaxassxk3503q69i03xi2y7sd6syqjznnjbys7c7m8gphc9a"}
          patch -RNp1 < ${rev "2f7e7d284bddd27d98a17beca4da0b6525d72913" "1n3qmq7ichwjpjsq8yicir7a8qxd3f37jp4hb2ciy07i0piva84c"}
          patch -RNp1 < ${rev "f4b3eb7efbe1d433d7dcf850430f99f0f0066347" "1dpyrmdrq39nn6n0n63g5ws2028rc3fc48ka9rdgji0405d1qp6k"}
          patch -RNp1 < ${rev "72b3cb68a702284122a16cbcdd87a621c29bb7a8" "1hh69rkd6i5gycf9g5dy2lvnzz3my7zl2xcid56hnpn4iyz0bja9"}
          patch -RNp1 < ${rev "a1a51f54dcb3863f9accfbf8c261407794d2bd13" "1ln9nhzs0r03alvbz15ym0vi17009ivw2hlxmprgyqpsjwvs0zq6"}
          patch -RNp1 < ${rev "3e0a9877eafef1f484987126cd453cc36cfdeb42" "16i56a8k5aym09vapbjf2safyf9dk68cwxjhbamhkm45rlv8db24"}
          patch -RNp1 < ${rev "5d0858ee9887ef5b99e09912d4379880979ab974" "077x9q97sw0sswzb51rzibhxxi3lljbpxp0p8j0cqnpmy44py3rm"}
          patch -RNp1 < ${rev "d1662e4beb4c1b757423c71107f7ec115ade19f5" "0jkd9ks69mry11fs338y1djx8mjz808634vydlcy7jwajyykk3qg"}
          patch -RNp1 < ${rev "dab54bd849cd9f109d1a9d16cb171eddec39f2a1" "1pi0srrzisgvhfm9qc7nqpk5pn89bcj223vvds697jz2j96d3zfr"}
          patch -RNp1 < ${rev "3864d2355493cbadedf59f0c2ee7ad7a306fad5a" "0y9yk8iiqspvraj0n46ygvx9mpbdf3gvn05cpf80gn4g6gpmcgra"}
          patch -RNp1 < ${rev "fca2f6c12b187763eaae23ed4932d6d049a469c3" "1xrs8dsw22xq4f5yp7vwddxvqb7afhic1llq3ibsxbpw4ln17jzb"}
          patch -RNp1 < ${rev "63fb4d8270d1db7a0034100db550f54e8d9859f1" "0xqp8nv8xwixnh9w47kvfky5ic9cpm2cfssq1ww5a4d8k4pdfbjp"}
          patch -RNp1 < ${rev "25adac6ede88d835110be20de0164d28c2187977" "1bgln83di6d0fyx6q7qar7r3m66lnjpi6if2866c2r70c4s6hi3l"}
          patch -RNp1 < ${rev "dc1a1ae450f1119b1f5714ed99b6049343676293" "17dazybjc808dy21ri7qsvwr2cx9k48k8wwji8msjmgcf2s6lmpk"}
          patch -RNp1 < ${rev "aafbbdb8bcc9b668008038dc6fcfba028c4cc6f6" "1g99z7z18kkg0aiikdz12q7mfyjvz6srf2pwr58y9ybh735mjbf8"}
          patch -RNp1 < ${rev "682093d0bdc24a55fcde37ca4f9cc9ed46c3c7df" "15krg20lf9m7dp8h4rzbld02yc8jr083g5viq3v6pv0jhw8lyimz"}
          patch -RNp1 < ${rev "21dc092b910f80616242761a00d8cdab2f8aa7bd" "0bhgss063243c4m3fah4zfk6fa7s3bxdxz8n38w072kx9nfkaaxg"}
          patch -RNp1 < ${rev "d7175e265537ffd24dbf8fd3bcaaa1764db03e13" "0xjc9h8r94j7qxy1811s86y06q9f0q1njh38rn30l7c4hj8xh5s9"}
          patch -RNp1 < ${rev "5306d0ff3c95e7b9b1c77fa2bb30b420d07879f7" "0rqlky9c51rimwj78q7djhnk5kkqlwbi8vnhsp91qph5w2blbb94"}
          patch -RNp1 < ${rev "00bc5eb73b95cbfe404fe18e1d0aadacc8ab4662" "0l705h04j3mgc34jk3bgb75s14lx6p6lxk7cxqfqal0b0pmb7zks"}
          patch -RNp1 < ${rev "a855591fd29f1f47947459f8710b580a4f90ce3a" "0risgiq5glc59829ng2g666522b4cbclmkhdr59fidsii41zca91"}
          patch -RNp1 < ${rev "34d85311f33335d2babff3983bb96fb0ce9bae5b" "08nsrfsgq4q55kd2l0205251010xg0kf8cpl4dlbj41jvw11xk04"}
          patch -RNp1 < ${rev "42c82012c7ac992a98930011647482fc94c63a87" "0c0bh3pi385p3kvy4i4iycf49qf5r9wzs9mdp1x6k8a3lcla3ndv"}
          patch -RNp1 < ${rev "4398e8aba2d2c96ee209f59658c2aa6caf26687a" "14v5qdlz9db0605ds99wbsxl1sk95450asj5cz1bj34cl70whfc5"}
          patch -RNp1 < ${rev "c9f5903e5a315989d03d48e4a53291be48fd8d89" "086rzi2v7wm7z7gnpaz041npa1wkvar4m4m2ak5h6vz1pq0gkyqy"}
          patch -RNp1 < ${rev "56dde41b6d91c589d861dca5d50ffa9f607da1db" "1bccgnvidaf291qww7m93j2n54g0kbllkqicnjavf373m942mn6x"}
          patch -RNp1 < ${rev "c3811e84617e409875957b3d0b43fc5be91f01f6" "08xa9g0p1phqmvlwbls3g64lrqmmwsscszqlc1x7ki1zhdb85la7"}
          patch -RNp1 < ${rev "799c7704e8877fe2ee73391f9f2b8d39e222b8d5" "0czs2kzxibzf0bdzsny2sr50rj55grmnlavcdgm4jnb9bykxxfyz"}
          patch -RNp1 < ${rev "399ccc032750e2658526fc70fa0bfee7995597df" "0gfrs3yrj92cj05fwchx9g3xizzv9w8m4s7hkn9fr9c3333j88va"}
          patch -RNp1 < ${rev "f7b45d419f94a6168e3d9a97fb2df21f448446f1" "0r1bm1krhz23h3vkzpn1nyqlj4ccrzmdi8zvisvjblvbf2przb6v"}
          patch -RNp1 < ${rev "6cb1d1ec4ffa77bbc2223703b93033bd86730a60" "0097q1xz03giv3d3m4cl4sr90q22yv0n30maxm5ccc1r41p2l2wx"}
          patch -RNp1 < ${rev "7c02cd8cf8e1b97df8f8bfddfeba68d7c7b4f820" "1wqmnkp4f1yq79ylpzrmnax5lm8xsjkwy80yb2vs6iii407jjh2y"}
          patch -RNp1 < ${rev "6f8d366b57e662981c68ba0bd29465f391167de9" "0rsrad789w9v1yaa82gphk8mhiiaq975gg54jr975kif79dbm86z"}
          patch -RNp1 < ${rev "74c2e9020f04b26e7ccf217d956ead740566e991" "0i65ibk5wknzcl3yzd79l5rsbcq5a4qi77iri2lwp048awma3q3q"}
          patch -RNp1 < ${rev "04d94e3c092bbbaee5ec1331930b11af58ced629" "0rbzwr82lv4v2lmj83fsmwrsbi2cb9dn7dwq6fgk3s6b3pmkydsv"}
          patch -RNp1 < ${rev "538b86bfc640ddcfd4d28b1e2660acdef0ce9b08" "0r53szzv5ii3hbg3gwmx172wdpk932hryy5irzcx029iahys38np"}
          patch -RNp1 < ${rev "3b8579d8a570eeeaf0d4e0667e748d484df138aa" "0sppvjjh387smf8gmm8f3pgal5r3imyvj9p3ailrjyw4wp4nkpax"}
          patch -RNp1 < ${rev "970c1bc49b804d0b7fa515292f27ac2fb4ef29e8" "12fr2b7ghkl8z8y3yqk9isx0maw0cjj3g0v26zglrx7jxqrglh2k"}
          patch -RNp1 < ${rev "f26e0ba212e6164eb7535f472415334d1a9c9044" "1179a4q6n3lqbxvksp788y97xg4zgcksgqz4q3y3vr60wmvk02vg"}
          patch -RNp1 < ${rev "bc52edc19d8a45b9062d9568652403251872026e" "0n1m6qnvbfcxg2ipq2jckj9szivrrmaavnmwbgy2lkbp6h4jg8rx"}
          patch -RNp1 < ${rev "b3655b5be5f137281e8757db4e6985018b21c296" "0dyf7yph91rw8aj05lgbv20dyx8c28d6xdxls4mkvmsw93pb2w5p"}
          patch -RNp1 < ${rev "95ffc879882fdedaf9fdf40eb1c556a025ae5bfd" "0q3l22i8539yxwhhny8lrpcwisglmgfrqi6bf0dn2pnwbds2f97m"}
          patch -RNp1 < ${rev "0dc309ef6ac54484d92f6558d6ca2f8e50eb28e2" "0dvyq5j3p60hpxbn7f8fa4nxnhb5lz6nj9dcsggkw9vlzcxy4spy"}
          patch -RNp1 < ${rev "25948222129fe48ac4c65a4cf093477d19d25f18" "15dkc8cmy4k4yck0425bd7yc3iw9nj9g02yisaqsr4m4x5dnc0ns"}
          patch -RNp1 < ${rev "7f481ea05faf02914ecbc1932703e528511cce1a" "1g021f699h86rjc63ak7pirzmqnyccgj4xyhczmcjj4032f8z269"}
          patch -RNp1 < ${rev "c45be242e5b6bc0a80796d65716ced8e0bc5fd41" "1g52g1r7m2zc1f3s407s5cc724vvr7gqhvzni4b84vzjpx9g0qf0"}
          patch -RNp1 < ${rev "d5154e7eea70a19fe528f0de6ebac0186651e0f3" "0xrwcbfm7jj9q1mls1hfnz5c9yaw3fcyw4jrdgvp4wwdp3d0plrp"}
          patch -RNp1 < ${rev "d39747f450ad4356868f46cfda9a870347cce9dd" "1nlvwffblamigjshr2jxxrcpb26rwmvgqb58jjfi1s6ysm1lpd86"}
          patch -RNp1 < ${rev "250f86b02389b2148471ad67bcc0775ff3b2c6ba" "1x0191ciqh8bspm6lzl6jqr5107r7g0gjn4ikl6gbca9ngm9byvn"}
          patch -RNp1 < ${rev "40ced5e054d1f16ce47161079c960ac839910cb7" "1zkhkv0wn3q3wjnnciz2lg9gf6sv1bbb3zvrc9v8w281hhy95q6z"}
          patch -RNp1 < ${rev "8bd3c8bf5a9ea4765f791f1f78f60bcf7060eba6" "1hz75l0ks8r2a1pax8z7b9xqfgvzz2d7s675ki7gxk7k9f0jk300"}
          patch -RNp1 < ${rev "87e4c289e46701c6f582e95c330eefb6fc5ec68a" "0sr86r6616zrabmarqzwk48saqk4dwx4fc7v12igrc7lm7hm7gy7"}
          patch -RNp1 < ${rev "51b6d45503e5849f28cce1a9aa9b7d3dba9de0fe" "1k9lamfnzr257zilv06s1gpis5ln95smspdv7ch2s73r3i6a6z1c"}
          patch -RNp1 < ${rev "c76418fbfd72e496c800aec28c5a1d713389287f" "0y7p5dwz96wi5xjhrfdg8ydg7lrzb7nx01sp524k7d3aj03w36a1"}
          patch -RNp1 < ${rev "37e9f0eadae9f62ccae8919a92686695927e9274" "0i9n16nn2hablagp39zxci6ki1ffqmmhjkmqxlr20zsmlhdf07z0"}
          patch -RNp1 < ${rev "dd182a924f89b948010ecc0d79f43aec83adfe65" "0vdkc2b357scixx2lg3qwm33xb2fycy5j5w8i9j9yinfackkzdrx"}
          patch -RNp1 < ${rev "4f10b95c8355c94e4c6f506322b80be7ae7aa174" "0l1zd4n28rgjwq9y2721cbba7sjdkx1ygrxj4yj8nlqyk9pw7gvw"}
          patch -RNp1 < ${rev "4239f2acf77d9eaa8166628d25c1336c1599df33" "1rdh8aa1b95bkqbg2ymx2qy7zkhjja6gdjng5f31zy7wwp31smkl"}
          patch -RNp1 < ${rev "3dd8eeeebdeec619570c764285bdcae82dee5868" "1rw8rb3i1sg3lyv6xa7pimrk08ldf65sydwi5qzlydpssxzgbsyy"}
          patch -RNp1 < ${rev "831c6a88aab78db054beb42ca9562146b53963e7" "02h5fr6rr3iy2bfmskapm5xill1xvqc9rnkzzwcv7db61z0fs12z"}
          patch -RNp1 < ${rev "2d0dc2d47ca6b2d4090dfe32efdba4f695b197ce" "0b4m6hi2mcixgq42mz9afyzq70c5g8n5bpnxy7vmx3cz7c6sqjxz"}

          echo "pulseaudio fixup to re-enable staging patches"
          patch -Np1 < ../patches/wine-hotfixes/staging/wine-pulseaudio-fixup.patch

          echo "manual revert of d8be85863fedf6982944d06ebd1ce5904cb3d4e1 for more audio fixing"
          patch -RNp1 < ../patches/wine-hotfixes/pending/revert-d8be858-faudio.patch

      ### END PROBLEMATIC COMMIT REVERT SECTION ###


      ### (2-2) WINE STAGING APPLY SECTION ###

          # these cause window freezes/hangs with origin
          # -W winex11-_NET_ACTIVE_WINDOW \
          # -W winex11-WM_WINDOWPOSCHANGING \

          # This was found to cause hangs in various games
          # Notably DOOM Eternal and Resident Evil Village
          # -W ntdll-NtAlertThreadByThreadId

          # ntdll-Junction_Points breaks Valve's CEG drm
          # the other two rely on it.
          # note: we also have to manually remove the ntdll-Junction_Points patchset from esync in staging.
          # we also disable esync and apply it manually instead
          # -W ntdll-Junction_Points \
          # -W server-File_Permissions \
          # -W server-Stored_ACLs \
          # -W eventfd_synchronization \

          echo "applying staging patches"
          ../wine-staging/patches/patchinstall.sh DESTDIR="." --all \
          -W winex11-_NET_ACTIVE_WINDOW \
          -W winex11-WM_WINDOWPOSCHANGING \
          -W ntdll-NtAlertThreadByThreadId \
          -W ntdll-Junction_Points \
          -W server-File_Permissions \
          -W server-Stored_ACLs \
          -W dwrite-FontFallback

          echo "Revert d4259ac on proton builds as it breaks steam helper compilation"
          patch -RNp1 < ../patches/wine-hotfixes/steamclient/d4259ac8e93_revert.patch

          echo "applying staging Compiler_Warnings revert for steamclient compatibility"
          # revert this, it breaks lsteamclient compilation
          patch -RNp1 < ../wine-staging/patches/Compiler_Warnings/0031-include-Check-element-type-in-CONTAINING_RECORD-and-.patch


      ### END WINE STAGING APPLY SECTION ###

      ### (2-3) GAME PATCH SECTION ###

          echo "mech warrior online"
          patch -Np1 < ../patches/game-patches/mwo.patch

          echo "ffxiv launcher"
          patch -Np1 < ../patches/game-patches/ffxiv-launcher-workaround.patch

          echo "assetto corsa"
          patch -Np1 < ../patches/game-patches/assettocorsa-hud.patch

          echo "mk11 patch"
          patch -Np1 < ../patches/game-patches/mk11.patch

          echo "killer instinct vulkan fix"
          patch -Np1 < ../patches/game-patches/killer-instinct-winevulkan_fix.patch

          # https://bugs.winehq.org/show_bug.cgi?id=51821
          echo "EVE Online - Fixe launcher 19.09"
          patch -Np1 < ../patches/game-patches/eve-online-launcher.patch

          echo "Castlevania Advance fix"
          patch -Np1 < ../patches/game-patches/castlevania-advance-collection.patch

      ### END GAME PATCH SECTION ###

      ### (2-4) PROTON PATCH SECTION ###

          echo "clock monotonic"
          patch -Np1 < ../patches/proton/01-proton-use_clock_monotonic.patch

          #WINE FSYNC
          echo "applying fsync patches"
          patch -Np1 < ../patches/proton/03-proton-fsync_staging.patch

          echo "proton futex waitv patches"
          patch -Np1 < ../patches/proton/57-fsync_futex_waitv.patch

          echo "LAA"
          patch -Np1 < ../patches/proton/04-proton-LAA_staging.patch

          echo "steamclient swap"
          patch -Np1 < ../patches/proton/08-proton-steamclient_swap.patch

          echo "protonify"
          patch -Np1 < ../patches/proton/10-proton-protonify_staging.patch

          echo "protonify-audio"
          patch -Np1 < ../patches/proton/11-proton-pa-staging.patch

          echo "steam bits"
          patch -Np1 < ../patches/proton/12-proton-steam-bits.patch

          # disabled for now, there was a massive controller HID update in WINE, so we're using that instead.
      #    echo "proton SDL patches"
      #    patch -Np1 < ../patches/proton/14-proton-sdl-joy.patch

          echo "Valve VR patches"
          patch -Np1 < ../patches/proton/16-proton-vrclient-wined3d.patch

          echo "amd ags"
          patch -Np1 < ../patches/proton/18-proton-amd_ags.patch

          echo "msvcrt overrides"
          patch -Np1 < ../patches/proton/19-proton-msvcrt_nativebuiltin.patch

          echo "atiadlxx needed for cod games"
          patch -Np1 < ../patches/proton/20-proton-atiadlxx.patch

          echo "valve registry entries"
          patch -Np1 < ../patches/proton/21-proton-01_wolfenstein2_registry.patch
          patch -Np1 < ../patches/proton/22-proton-02_rdr2_registry.patch
          patch -Np1 < ../patches/proton/23-proton-03_nier_sekiro_ds3_registry.patch
          patch -Np1 < ../patches/proton/24-proton-04_cod_registry.patch
          patch -Np1 < ../patches/proton/32-proton-05_spellforce_registry.patch
          patch -Np1 < ../patches/proton/33-proton-06_shadow_of_war_registry.patch
          patch -Np1 < ../patches/proton/41-proton-07_nfs_registry.patch
          patch -Np1 < ../patches/proton/45-proton-08_FH4_registry.patch
          patch -Np1 < ../patches/proton/46-proton-09_nvapi_registry.patch
          patch -Np1 < ../patches/proton/47-proton-10_dirt_5_registry.patch
          patch -Np1 < ../patches/proton/54-proton-11_death_loop_registry.patch
          patch -Np1 < ../patches/proton/56-proton-12_disable_libglesv2_for_nw.js.patch
          patch -Np1 < ../patches/proton/58-proton-13_atiadlxx_builtin_for_gotg.patch
          patch -Np1 < ../patches/proton/60-proton-14-msedgewebview-registry.patch
          patch -Np1 < ../patches/proton/61-proton-15-FH5-amd_ags_registry.patch
          patch -Np1 < ../patches/proton/62-proton-16-Age-of-Empires-IV-registry.patch


          echo "valve rdr2 fixes"
          patch -Np1 < ../patches/proton/25-proton-rdr2-fixes.patch

          echo "valve rdr2 bcrypt fixes"
          patch -Np1 < ../patches/proton/55-proton-bcrypt_rdr2_fixes.patch

          echo "apply staging bcrypt patches on top of rdr2 fixes"
          patch -Np1 < ../patches/wine-hotfixes/staging/0002-bcrypt-Add-support-for-calculating-secret-ecc-keys.patch
          patch -Np1 < ../patches/wine-hotfixes/staging/0003-bcrypt-Add-support-for-OAEP-padded-asymmetric-key-de.patch

          echo "set prefix win10"
          patch -Np1 < ../patches/proton/28-proton-win10_default.patch

          echo "dxvk_config"
          patch -Np1 < ../patches/proton/29-proton-dxvk_config.patch

          echo "mouse focus fixes"
          patch -Np1 < ../patches/proton/38-proton-mouse-focus-fixes.patch

          echo "CPU topology overrides"
          patch -Np1 < ../patches/proton/39-proton-cpu-topology-overrides.patch

          echo "fullscreen hack"
          patch -Np1 < ../patches/proton/41-valve_proton_fullscreen_hack-staging-tkg.patch

          echo "fullscreen hack fsr patch"
          patch -Np1 < ../patches/proton/48-proton-fshack_amd_fsr.patch

          echo "proton QPC performance patch"
      #    patch -Np1 < ../patches/proton/49-proton_QPC.patch
          patch -Np1 < ../patches/proton/49-proton_QPC-update-replace.patch

          echo "proton LFH performance patch"
          patch -Np1 < ../patches/proton/50-proton_LFH.patch

          echo "proton font patches"
          patch -Np1 < ../patches/proton/51-proton_fonts.patch

          echo "proton quake champions patches"
          patch -Np1 < ../patches/proton/52-proton_quake_champions_syscall.patch

          echo "proton battleye patches"
          patch -Np1 < ../patches/proton/59-proton-battleye_patches.patch

      #    disabled for now, needs rebase. only used for vr anyway
      #    echo "proton openxr patches"
      #    patch -Np1 < ../patches/proton/37-proton-OpenXR-patches.patch

      ### END PROTON PATCH SECTION ###

      ### START MFPLAT PATCH SECTION ###

          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0001-Revert-winegstreamer-Get-rid-of-the-WMReader-typedef.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0002-Revert-wmvcore-Move-the-async-reader-implementation-.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0003-Revert-winegstreamer-Get-rid-of-the-WMSyncReader-typ.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0004-Revert-wmvcore-Move-the-sync-reader-implementation-t.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0005-Revert-winegstreamer-Translate-GST_AUDIO_CHANNEL_POS.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0006-Revert-winegstreamer-Trace-the-unfiltered-caps-in-si.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0007-Revert-winegstreamer-Avoid-seeking-past-the-end-of-a.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0008-Revert-winegstreamer-Avoid-passing-a-NULL-buffer-to-.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0009-Revert-winegstreamer-Use-array_reserve-to-reallocate.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0010-Revert-winegstreamer-Handle-zero-length-reads-in-src.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0011-Revert-winegstreamer-Convert-the-Unix-library-to-the.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0012-Revert-winegstreamer-Return-void-from-wg_parser_stre.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0013-Revert-winegstreamer-Move-Unix-library-definitions-i.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0014-Revert-winegstreamer-Remove-the-no-longer-used-start.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0015-Revert-winegstreamer-Set-unlimited-buffering-using-a.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0016-Revert-winegstreamer-Initialize-GStreamer-in-wg_pars.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0017-Revert-winegstreamer-Use-a-single-wg_parser_create-e.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0018-Revert-winegstreamer-Fix-return-code-in-init_gst-fai.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0019-Revert-winegstreamer-Allocate-source-media-buffers-i.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0020-Revert-winegstreamer-Duplicate-source-shutdown-path-.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0021-Revert-winegstreamer-Properly-clean-up-from-failure-.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-reverts/0022-Revert-winegstreamer-Factor-out-more-of-the-init_gst.patch

          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0001-winegstreamer-Activate-source-pad-in-push-mode-if-it.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0002-winegstreamer-Push-stream-start-and-segment-events-i.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0003-winegstreamer-Introduce-H.264-decoder-transform.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0004-winegstreamer-Implement-GetInputAvailableType-for-de.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0005-winegstreamer-Implement-GetOutputAvailableType-for-d.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0006-winegstreamer-Implement-SetInputType-for-decode-tran.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0007-winegstreamer-Implement-SetOutputType-for-decode-tra.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0008-winegstreamer-Implement-Get-Input-Output-StreamInfo-.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0009-winegstreamer-Add-push-mode-path-for-wg_parser.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0010-winegstreamer-Implement-Process-Input-Output-for-dec.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0011-winestreamer-Implement-ProcessMessage-for-decoder-tr.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0012-winegstreamer-Semi-stub-GetAttributes-for-decoder-tr.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0013-winegstreamer-Register-the-H.264-decoder-transform.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0014-winegstreamer-Introduce-AAC-decoder-transform.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0015-winegstreamer-Register-the-AAC-decoder-transform.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0016-winegstreamer-Rename-GStreamer-objects-to-be-more-ge.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0017-winegstreamer-Report-streams-backwards-in-media-sour.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0018-winegstreamer-Implement-Process-Input-Output-for-aud.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0019-winegstreamer-Implement-Get-Input-Output-StreamInfo-.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0020-winegstreamer-Semi-stub-Get-Attributes-functions-for.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0021-winegstreamer-Introduce-color-conversion-transform.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0022-winegstreamer-Register-the-color-conversion-transfor.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0023-winegstreamer-Implement-GetInputAvailableType-for-co.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0024-winegstreamer-Implement-SetInputType-for-color-conve.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0025-winegstreamer-Implement-GetOutputAvailableType-for-c.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0026-winegstreamer-Implement-SetOutputType-for-color-conv.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0027-winegstreamer-Implement-Process-Input-Output-for-col.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0028-winegstreamer-Implement-ProcessMessage-for-color-con.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0029-winegstreamer-Implement-Get-Input-Output-StreamInfo-.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0030-mf-topology-Forward-failure-from-SetOutputType-when-.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0031-winegstreamer-Handle-flush-command-in-audio-converst.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0032-winegstreamer-In-the-default-configuration-select-on.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0033-winegstreamer-Implement-MF_SD_LANGUAGE.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0034-winegstreamer-Only-require-videobox-element-for-pars.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0035-winegstreamer-Don-t-rely-on-max_size-in-unseekable-p.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0036-winegstreamer-Implement-MFT_MESSAGE_COMMAND_FLUSH-fo.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0037-winegstreamer-Default-Frame-size-if-one-isn-t-availa.patch
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-streaming-support/0038-mfplat-Stub-out-MFCreateDXGIDeviceManager-to-avoid-t.patch

          # Needed specifically for proton, not needed for normal wine
          echo "proton mfplat dll register patch"
          patch -Np1 < ../patches/proton/30-proton-mediafoundation_dllreg.patch

          # Needed for Nier Replicant
          echo "proton mfplat nier replicant patch"
          patch -Np1 < ../patches/wine-hotfixes/staging/mfplat_dxgi_stub.patch

          # Needed for mfplat video format conversion, notably resident evil 8
          echo "proton mfplat video conversion patches"
          patch -Np1 < ../patches/proton/34-proton-winegstreamer_updates.patch

          # Needed for godfall intro
          echo "mfplat godfall fix"
          patch -Np1 < ../patches/wine-hotfixes/mfplat/mfplat-godfall-hotfix.patch

          # missing http: scheme workaround see: https://github.com/ValveSoftware/Proton/issues/5195
          echo "The Good Life (1452500) workaround"
          patch -Np1 < ../patches/game-patches/thegoodlife-mfplat-http-scheme-workaround.patch


      ### END MFPLAT PATCH SECTION ###



      ### (2-5) WINE HOTFIX SECTION ###

          echo "hotfix for beam ng right click camera being broken with fshack"
          patch -Np1 < ../patches/wine-hotfixes/pending/hotfix-beam_ng_fshack_fix.patch

          # keep this in place, proton and wine tend to bounce back and forth and proton uses a different URL.
          # We can always update the patch to match the version and sha256sum even if they are the same version
          echo "hotfix to update mono version"
          patch -Np1 < ../patches/wine-hotfixes/pending/hotfix-update_mono_version.patch

          echo "add missing stub for fh5"
          patch -Np1 < ../patches/wine-hotfixes/testing/fh5-uiauto.patch

          # https://github.com/Frogging-Family/wine-tkg-git/commit/ca0daac62037be72ae5dd7bf87c705c989eba2cb
          echo "unity crash hotfix"
          patch -Np1 < ../patches/wine-hotfixes/pending/unity_crash_hotfix.patch

          # https://bugs.winehq.org/show_bug.cgi?id=52017
          echo "fix for broken file browser"
          patch -Np1 < ../patches/wine-hotfixes/pending/hotfix-file_browser_fix.patch

          echo "fix for prefix creation breakage caused by e5d3783"
          patch -Np1 < ../patches/wine-hotfixes/pending/hotfix-e5d3783-refression-fix.patch

      #    disabled, not compatible with fshack, not compatible with fsr, missing dependencies inside proton.
      #    patch -Np1 < ../patches/wine-hotfixes/testing/wine_wayland_driver.patch


      ### END WINE HOTFIX SECTION ###
    '';
  });
}