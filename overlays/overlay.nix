self: super: let
  nativeStdenv = super.impureUseNativeOptimizations super.stdenv;
  llvmNativeStdenv = super.impureUseNativeOptimizations super.llvmPackages_latest.stdenv;

  withFlags = pkg: flags:
    pkg.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = old.NIX_CFLAGS_COMPILE or "" +
        super.lib.concatMapStrings (x: " " + x) flags;
    });

  withStdenv = newStdenv: pkg:
    pkg.override { stdenv = newStdenv; };

  withStdenvAndFlags = newStdenv: pkg:
    withFlags (withStdenv newStdenv pkg);

  withNativeAndFlags = withStdenvAndFlags nativeStdenv;
  withLLVMNative = withStdenv llvmNativeStdenv;
  withLLVMNativeAndFlags = withStdenvAndFlags llvmNativeStdenv;

  withRustNative = pkg: pkg.overrideAttrs (old: {
    RUSTFLAGS = old.RUSTFLAGS or "" + " -Ctarget-cpu=native -Copt-level=3 -Cdebuginfo=0 -Ccodegen-units=1";
  });

  withRustNativeAndPatches = pkg: patches: withRustNative (pkg.overrideAttrs (old: {
    patches = old.patches or [] ++ patches;
  }));
in {
  qemu = withLLVMNative (super.qemu.override {
    hostCpuOnly = true;
    smbdSupport = true;
  });

  sudo = withLLVMNative (super.sudo.override {
    withInsults = true;
  });

  ibus = super.ibus.override {
    withWayland = true;
  };

  rust-analyzer-unwrapped = withRustNativeAndPatches (super.rust-analyzer-unwrapped.override rec {
    version = "2020-08-24";
    rev = version;
    sha256 = "zrY+YrMoL9bZ4Jxn/0t5RYYRCOLYyXzkfXmWgjPUBYc=";
    cargoSha256 = "ffiv0etVYFtOTFxy3aGxLZzUDdMC3FP89aqTZAcx+5g=";
    doCheck = false;
  }) [ ./patches/rust-analyzer.patch ];

  vscode-with-extensions = super.vscode-with-extensions.override {
    vscode = super.vscodium;

    vscodeExtensions = with super.vscode-extensions; [
      bbenoist.Nix
      matklad.rust-analyzer
    ] ++ super.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "vscode-todo-plus";
        publisher = "fabiospampinato";
        version = "4.17.1";
        sha256 = "00gcv66plxalmipmbhv11b1q3dhjs81ry0k4p5313m4kbn9s7dg2";
      }
      {
        name = "graphql-for-vscode";
        publisher = "kumar-harsh";
        version = "1.15.3";
        sha256 = "1x4vwl4sdgxq8frh8fbyxj5ck14cjwslhb0k2kfp6hdfvbmpw2fh";
      }
      {
        name = "better-toml";
        publisher = "bungcip";
        version = "0.3.2";
        sha256 = "08lhzhrn6p0xwi0hcyp6lj9bvpfj87vr99klzsiy8ji7621dzql3";
      }
      {
        name = "errorlens";
        publisher = "usernamehw";
        version = "3.1.1";
        sha256 = "1dlkxp54pxc92sm6zs24nwcss9204w1k977k9gh1dqfzsaacg9kj";
      }
      {
        name = "tokyo-night";
        publisher = "enkia";
        version = "0.5.6";
        sha256 = "096dpvi8ja1qandhp53gmcqrkj5k8gjyab3nhjl4lz3jqdav13bs";
      }
      {
        name = "svelte-vscode";
        publisher = "svelte";
        version = "101.13.0";
        sha256 = "S7yyjJ7ksdhiLbdOaocps9Qr2s9IVSrCIJBofN7aZTk=";
      }
    ];
  };

  waybar = withLLVMNativeAndFlags (super.waybar.override {
    pulseSupport = true;
    mpdSupport = false;
    nlSupport = false;
  }) [ "-O3" ];

  redshift = super.redshift.overrideAttrs (oldAttrs: rec {
    pname = "redshift-wlr";
    version = "2019-04-17";

    src = super.fetchFromGitHub {
      owner = "minus7";
      repo = "redshift";
      rev = "eecbfedac48f827e96ad5e151de8f41f6cd3af66";
      sha256 = "0rs9bxxrw4wscf4a8yl776a8g880m5gcm75q06yx2cn3lw2b7v22";
    };
  });

  # Latest Wine staging with fsync and Proton patches from GloriousEggroll.
  # When Wine is updated, changed patches should be checked for at https://github.com/GloriousEggroll/proton-ge-custom/blob/proton-ge-5/patches/protonprep.sh
  wine = ((super.wine.override {
    # Note: we cannot set wineRelease to staging here, as it will no longer allow us
    # to use overrideAttrs
    wineBuild = "wineWow";

    netapiSupport = false;
    cupsSupport = false;
    gphoto2Support = false;
    saneSupport = false;
    openclSupport = false;
    gsmSupport = false;
  }).overrideAttrs (oldAttrs: rec {
    version = "5.9";
    geVersion = "${version}-GE-5-ST";

    src = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      rev = "wine-${version}";
      sha256 = "kyZt3fSiRlyDNnX9oR23lQlCN3ZFrPRlSHTFdBhqZag=";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "X3VWHdVTEeL7d6Ay5ZDeetzFbMcrk30e86U1YzNLhME=";
    };

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    patchAbsPath = path: sha256:
      # fetchpatch produces invalid patches(https://github.com/NixOS/nixpkgs/issues/37375)
      super.fetchurl {
        url = "https://raw.githubusercontent.com/GloriousEggroll/proton-ge-custom/${drv.geVersion}/${path}.patch";
        inherit sha256;
      };

    patch = name: patchAbsPath "patches/${name}";
  in {
    name = "wine-wow-${drv.version}-staging";

    buildInputs = drv.buildInputs ++ [
      super.git
      super.perl
      super.utillinux
      super.autoconf
      super.python3
      super.perl
    ];

    protonPatches = let
      qdp = commit: patch "wine-hotfixes/backports-for-5.9/QueryDisplayConfig/${commit}";
    in [
      # 5.9 backports
      (qdp "8a4ec0addba76bf3b34a9782556364ab4161dc22" "tH0qU+oqVASCAO2K21cId+J6IKGF2fLxDuCP3lQhpCI=")
      (qdp "ae4804d502fecab835146043010f53377bf1b65a" "5J8SJ1JdTzpe8GIonl0YUtg8PhDnuuRKlShYZjjiYTA=")
      (qdp "f1e7d5bbd6e8817f7266c7144b747115a52893da" "lnIKcHVnvg6iy6x7Rjy50p0MiWaVr2IErwF2NCcRMLE=")
      (qdp "411fe4f1c3fc45ec6bed0a1beaf61c67f6cf6294" "mgRYPpFRKkKLEEoh1cmWD03dPGw7skvgRpxqW5apOj4=")
      (qdp "8cd6245b7633abccd68f73928544ae4de6f76d52" "7jZpKPZ2iQqdxa9rEaedLzLm+LyrEJYYMKRR8Ufh1ew=")
      (qdp "707fcb99a60015fcbb20c83e9031bc5be7a58618" "BVHty+oZ/jYNo7xAsSLBj7HLl60tdeD/YLdchkTBlVk=")
      (qdp "c36e26f41d1653d11ac47c7890497cc14ceb99ba" "lhFX1kWXdmPfYnz+y5KF+53gjqwHc0l1JQ6/xBojzjo=")
      (qdp "b582ab26f91b1b189409cf9d058ffd7c8827ccb4" "Kccgjn1f1aBgQTNBqqTLDZXmxF6gPLO/S8ou72kWp9A=")
      (qdp "1b33e0f72e87e3c3af905df27c339887f4cb5a18" "9/dMDNgmPrRJSHfLJH4uRIRb7HWFTBb4Z3NXpl2/k7w=")
      (qdp "e3eb89d5ebb759e975698b97ed8b547a9de3853f" "lVgiL7V4EAGlSu7Iaj9JxIB7vdgo5LiI7fzz1w3iq88=")
      (qdp "988d31b696b2bdc7a0aa6fc626cd50f034dd05ec" "zW3SYWW4gUfF2oEJlCALcm2zXXgy9jwZbIfMLFjVTLw=")
      (qdp "343043153b44fa46a2081fa8a2c171eac7c8dab6" "RC+j9DINCa+SpGlTIXFmQTnQjHK97iqytuv0bHFNH90=")
      (qdp "b5d58ff69c9b01d42b5dd12f5652d5cf2859d4b8" "U75TMiurJtuQfLujqy2L16ScDheO4JzOPg6kwhF4vT4=")
      (qdp "3db619d46e70a398a06001573fb42b0a32d81209" "UREHjMcZVbZ9sQgWbmx+x1mqyQ4GNHmulpArn5M8QDI=")
      (qdp "0a2d6378d80a1594cae6c7ab0e5d31b8fe11703b" "o+4JLkjzWcnc2wtGyIoqQ+KeagWWfDYg8A8FD+Dq9iQ=")
      (qdp "203bd057cf2268f03558be475ce2ba984f93e581" "5Jqz4isdzSTzk993PRknnKygHAMPsU+mBoHMgluLaEM=")
      (qdp "c4a01d0a65905f33cbfe90f150b2d23a02c4e793" "sqh98DybpNSuC4XSiY6tafvjQ8pmAvfMUWiT2FNBQk8=")
      (qdp "ca1d31fc3b153a38c38b27b873052ce6f04cb5d4" "ymMC//FkWD0aqoPdMWCejFr4Dwfm5uyx3S7oUnThPmU=")
      (qdp "634cb775c27b61ad6ce1fbe3e9972b0edfa31dcb" "6yxTjKxgAs4/IBQCDWWN3A4ohuLVzjpnTE0+IVHAdck=")
      (qdp "2affb854e524dde962f983a36628f22fe9e165c7" "qEsimr4E59bsqZJcArOzQsNBC6faD+15o92ZkyQsRCU=")
      (qdp "13e3d8f6354d23226ac5e7b1a2fb3aeb81d0b402" "GrcIH70d9po5gLi6WxF/ZmpsPEa4RAMeqv0nOHcSd6I=")
      (qdp "6b6a7124a67c6eadbe4408163f93dbf0379b6565" "ebmhgRxOO3zuUZGt8kgyugOMsTpwZeeuHYFYMFx867w=")
      (qdp "145cfce1135a7e59cc4c89cd05b572403f188161" "jZL2eRaREzBaeuftf9OsHpvx1G2aT8D9WLVnErtFy+g=")
      (qdp "408a5a86ec30e293bf9e6eec4890d552073a82e8" "uacR+VPGwId0vK5xuOK7dzEgIW2Zb8V0P4ogNT4kqj4=")
      (qdp "8007d19c2792b5b177bd7200dc3567df4677dc0c" "7vj0pBg6zYkl3sjvxXhAM4TuvGdSaF7F67HdMfyjEJU=")
      (qdp "6f9d20806e821ab07c8adf81ae6630fae94b00ef" "AKjW2alVEF/lk6TVTQMmEwPewf1q6tpqLBcI+07vrhM=")
      (qdp "aec196878875e92d0b404a6f982cea6667768696" "OwdlbwE4eUDWq43QI/kukhSFXX+u5Dfg5phfwy/X0Z8=")
      (qdp "5dd03cbc8f5cc8fa349d1ce0f155139094eff56c" "vcd5Oj4pRMt1W5+2J/4/HZBomheJRGAsUTyvHV7yg/M=")
      (qdp "59c206f9dc25a9f9cfd772bf87288b7fb65f355f" "7QWX8du76BKLqMGtZYZA1MemxAcNUEEGEPBSRblwLbg=")
      (qdp "1899830b02218b89bb1669c265bd04d6750347fb" "YgJk9hHIQDmSHI5tuc2vSMNBuc7foW2MvA2prvYA594=")
      (qdp "a94101672e1f98a364e0605bf8299474cf950821" "jmhSRcc+fak+CdpHaqu9PWOojhv11PW+PxbIeyNxwzI=")
      (qdp "2e1c48f3517fa967ae9f9a0794c88e6d4e5e77f2" "aW9heUPle14605YqTzxCe8kxKpwbS5tx0m29u7K3hsc=")
      (qdp "5fba152eea0bd8b7a2553beea05370dc140ed740" "m4s03SBD4G1FraOVtahqMskxX7xIgRtHUhD5lendWug=")
      (qdp "cb127e11ad381789b11a3c40913f6186a48d0f37" "uoH6rjxjizwy8MfHO+8Z7OT4z9rRmNfcKS5pN2R3OOo=")
      (qdp "3a3c7cbd209e23cc6ee88299b3ba877ab20a767f" "WAGBW2uGkcG0TGQ7LCWRgfAYc5llyanmcBuEOCFV+nk=")
      (qdp "27ed9c95a2bbdbf7d86309cf1b9c9fefc157a0fe" "doVlWsO/lv8KZTylpENz04gi9XAN7BpaorjLgPXH4Ug=")
      (qdp "8949f570865fe72e28b4b7ef57c5c903d9a711b0" "jb+SNkSS/S0TOrtdL+fvmKDkUrVng7VePecc8Rhlkzg=")
      (qdp "894c6566ab25d0fb4a1a6d7e061041fc14906662" "8JFJtmVTSjU81wSZmanxU08xvS8t+Hw/0qB07DlJl6M=")
      
      # 5.10 backports
      (patch "wine-hotfixes/backports-for-5.9/25e9e91c3a4f6c1c134d96a5c11517178e31f111" "Znuaikn0bUt+Ms47vX6QENs+ursaADKHNcs4yORfiOw=")
      (patch "wine-hotfixes/backports-for-5.9/4ed26b63ca0305ba750c4f38002cf1eb674f688c" "MzOCtIgcSTXAIQV/r2+/6bQdxywwwQ7VbhbFKCCsCXw=")
      (patch "wine-hotfixes/backports-for-5.9/ea9b507380b4415cf9edd3643d9bcea7ab934fbd" "wQPrO+cl6UrQESqA0sczZr0WUchK6iFUNEI874NTGPA=")
      (patch "wine-hotfixes/backports-for-5.9/c96fa96c167808bf1c9a42b72c9e7ab6567eca75" "eoZ1F7hidTdYC2sorYJchvk1hdUmJp9h4XpIP2mVrIw=")

      (patch "wine-hotfixes/backports-for-5.9/winhttp_backports" "9kvwE/sbprGwIY5jm8tNCGU/1XGXoAfwbiCJE1K+4w8=")

      # Vulkan backports
      (patch "wine-hotfixes/backports-for-5.9/vulkan/winevulkan-1.2.142" "L9wsdeV6fgCLTkAgMmlupwt24a8c3fXQitf7nNhGIzo=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/winevulkan-change_blacklist_to_more_neutral_word" "ijU0zlJRUlZtxewazYVNfFNoOcEnFNDRzpZexNJKubY=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/winevulkan-1.2.145" "kn+PjytdyMJ15PZmcV+lCiILxzxbI74fD/ExTcw69G4=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/winevulkan-dont_initialize_vulkan_driver_in_dllmain" "JCd68oMxPZVsNLzZAoRyw6rlg9yCJ1bfS22Q7L3iTTE=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/380b7f28253c048d04c1fbd0cfbc7e804bb1b0e1" "AmgqS9dpxqIZZ+bO+ntLGXCRh7yhODyCO7c7MjfLW6k=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/262e4ab9e0eeb126dde5cb4cba13fbf7f1d1cef0" "HAcfRws23mFFIGDv54BwE0o5+7G6cEt+0P/Nl2Kh4KA=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/314cd9cdd542db658ce7a01ef0a7621fc2d9d335" "EYJtRY0SSTx3nBnxhs16KqTvKLaq4ce1K52XnXx5yxM=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/a455ff61b40ff73b48d0ccc9c1f14679bb65ab8d" "zwG1ALQW6peXN2GLtDIa+hOsZzO1eoglr5Ai79iBXNo=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/6299969a60b2bda85e69a3569c5d4970d47b3cc6" "E4HHYV7ZFssg3A9U2AHUHNt/vVyGy1RE+QTx7lBiFWY=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/8bd62231c3ab222c07063cb340e26c3c76ff4229" "NUFahpYjHn31ppesZ2fPA8W+dcRu6r74/1VupGyNfY8=")
      (patch "wine-hotfixes/backports-for-5.9/vulkan/winevulkan_poe_backport" "IVPFc/rfVjJI0MTY5R2+PQ5RsUtBDu4d017YtrYgKzc=")

      (patch "proton-5.9/proton-use_clock_monotonic" "zsBff34VjG7Sf+O0u7RfIBXV1Ts9V8fnsfUgEuUbnW4=")
      (patch "proton-5.9/proton-amd_ags" "0phhvka6rzrxl3i44w4y97c6sphsif0zh4v7iw3izg2nak2rmhi9")
      (patch "proton-5.9/proton-FS_bypass_compositor" "0n8w2yrdrg9nfnnis50jnax5xh7yxvx0zw1kgg782n9mxjr2j0x1")
      (patch "wine-hotfixes/winevulkan-childwindow" "1hnc413100ggsq4pxad0ih2n51p435kkzn5bv642mf8dmsh0yk1l")
      (patch "proton-5.9/proton-fsync_staging" "1ylm6x9qj8xwrr4wxzq1dbbd7dfx13d3nv3d8m1xans85i4z48yl")
      (patch "proton-5.9/proton-fsync-spincounts" "0q0nm98xvpy5i0963giwsjrv3fy28g2649v7yivyvpv7is91w0pb")
      (patch "proton-5.9/proton-LAA_staging" "/NY6yB+SsVIpDU2yar1c2JX6yrC9pF8NCC8gnYvn674=")
      (patch "proton-5.9/proton-protonify_staging" "gP8pY/7p547vcKc6ckAutRL3MuzC3y7lU6qT2udBlfg=")
      (patch "proton-5.9/proton-pa-staging" "1ixh8gbiqdn0nf1gyzxyni83s3969d7l21inmnj1bwq0shhwnbyv")
      (patch "proton-5.9/proton-winevulkan-nofshack" "wyfvXYZUKlWhUacd042vAfSbpWLlSdmwTweOCgvTzGM=")
      (patch "wine-hotfixes/backports-for-5.9/media_foundation_alpha" "rMGf1zIqL/hSXMH190tGZImi3HruH/f6FhhaXc7nhvA=")
      (patch "wine-hotfixes/media_foundation/proton_mediafoundation_dllreg" "0wcrh99skvrag7j34sf519yjypcr1n431pq9kqkya14hn4jxij86")
    ];

    preStagingPatches = [
      (patch "wine-hotfixes/backports-for-5.9/staging/8402c959617111ac13a2025c3eb7c7156a2520f8" "6bwuGs1Ib4r0Umtg6E0Et/IM4duo4JqsCfm6DAJrlRs=")
    ];

    reverts = let
      commit = hash: sha256: super.fetchurl {
        url = "https://github.com/wine-mirror/wine/commit/${hash}.patch";
        inherit sha256;
      };
    in [];

    postPatchReverts = [ ./patches/wine_revert.patch ];

    postPatch =
      let
        vulkanVersion = "1.2.148";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "sTw3RSa2BSKE6aLRuyuN1dZRNu6Ov2sGcoK6jIT2sDM=";
        };
      in ''
        for revert in $reverts; do
          echo "!! applying revert ''${revert}"
          patch -NRp1 < "$revert"
        done

        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w -R patches/

        for patch in $preStagingPatches; do
          echo "!! applying pre-staging patch ''${patch}"
          patch -Np1 < "$patch"
        done

        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all \
          -W server-Desktop_Refcount \
          -W ws2_32-TransmitFile \
          -W dinput-SetActionMap-genre \
          -W dinput-axis-recalc \
          -W dinput-joy-mappings \
          -W dinput-reconnect-joystick \
          -W dinput-remap-joystick \
          -W user32-window-activation
        cd ..

        echo "applying Proton patches.."

        for patch in $protonPatches; do
          echo "!! applying ''${patch}"
          patch -Np1 < "$patch" || true
        done

        for revert in $postPatchReverts; do
          echo "!! applying post-patch revert ''${revert}"
          patch -NRp1 < "$revert"
        done

        echo "applying custom patches.."

        # Fixes X-Plane 11 not launching with Mesa
        # https://gitlab.freedesktop.org/mesa/mesa/issues/106
        patch -Np1 < ${./patches/wine_xplane.patch}

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
      '';
  });

  # git version of RPCS3
  rpcs3 = (super.rpcs3.override {
    waylandSupport = true;
    alsaSupport = false;

    stdenv = llvmNativeStdenv;
  }).overrideAttrs (oldAttrs: rec {
    name = "rpcs3-${version}";

    commit = "8ca53f9c843712c25988f44761417f526fc26212";
    gitVersion = "9165-${builtins.substring 0 7 commit}";
    version = "0.0.7-${gitVersion}";

    src = super.fetchgit {
      url = "https://github.com/RPCS3/rpcs3";
      rev = "${commit}";
      sha256 = "0gmirrs8j7kzjjp01d7n1nlmjc78lcj4zdn2jk6j853spcf44jb1";
    };

    buildInputs = oldAttrs.buildInputs ++ [ super.vulkan-headers super.libglvnd ];

    cmakeFlags = oldAttrs.cmakeFlags ++ [
      "-DUSE_DISCORD_RPC=OFF"
      "-DUSE_NATIVE_INSTRUCTIONS=ON"
    ];

    preConfigure = ''
      cat > ./rpcs3/git-version.h <<EOF
      #define RPCS3_GIT_VERSION "${gitVersion}"
      #define RPCS3_GIT_BRANCH "HEAD"
      #define RPCS3_GIT_VERSION_NO_UPDATE 1
      EOF
    '';

    postInstall = let
      mlaaPatch = super.fetchurl {
        name = "patch.yml";
        url = "https://rpcs3.net/blog/wp-content/uploads/2020/common/mlaa/patch.yml";
        sha256 = "018mm3zg9zvdwqk61ixjvz6z1ky2qlxlzaqfmdqszgf4rj8yk4mg";
      };
    in oldAttrs.postInstall or "" + ''
      cp ${mlaaPatch} $out/bin/patch.yml
    '';
  });

  the-powder-toy = withLLVMNativeAndFlags super.the-powder-toy [ "-O3" "-flto" ];

  arc-theme = super.arc-theme.overrideAttrs (oldAttrs: {
    configureFlags = oldAttrs.configureFlags or [] ++ [
      "--disable-light"
      "--disable-cinnamon"
      "--disable-gnome-shell"
      "--disable-metacity"
      "--disable-unity"
      "--disable-xfwm"
      "--disable-plank"
      "--disable-openbox"
    ];
  });

  nativeFfmpeg = withLLVMNative super.ffmpeg_4;

  ### Modifications to make some packages run as fast as possible

  alacritty = withRustNativeAndPatches super.alacritty [ ./patches/alacritty.patch ];

  nushell = withRustNativeAndPatches (super.nushell.overrideAttrs (oldAttrs: rec {
    doCheck = false;
  })) [ ./patches/nushell.patch ];

  ripgrep = withRustNativeAndPatches super.ripgrep [ ./patches/ripgrep.patch ];

  mpv = withLLVMNativeAndFlags (super.mpv-unwrapped.override {
    vapoursynthSupport = true;
  }) [ "-O3" "-flto" ];

  vapoursynth = withLLVMNativeAndFlags super.vapoursynth [ "-O3" "-flto" ];
  vapoursynth-mvtools = withLLVMNativeAndFlags super.vapoursynth-mvtools [ "-O3" "-flto" ];

  vapoursynth-plugins = super.buildEnv {
    name = "vapoursynth-plugins";
    paths = [ self.vapoursynth-mvtools ];
    pathsToLink = [ "/lib" ];
  };

  qbittorrent = super.qbittorrent.overrideAttrs (oldAttrs: rec {
    NIX_CFLAGS_COMPILE = oldAttrs.NIX_CFLAGS_COMPILE or "" +
      " -O3 -flto -march=native";
  });

  sway = withNativeAndFlags super.sway [ "-O3" "-flto" ];
  wlroots = withNativeAndFlags super.wlroots [ "-O3" "-flto" ];
  mako = withNativeAndFlags super.mako [ "-O3" ];

  faudio = withNativeAndFlags super.faudio [ "-O3" ];
  vkd3d = withNativeAndFlags super.vkd3d [ "-O3" ];

  ### Custom packages

  anup = withRustNative (super.callPackage ./pkgs/anup.nix { });
  bcnotif = withRustNative (super.callPackage ./pkgs/bcnotif.nix { });
  wpfxm = withRustNative (super.callPackage ./pkgs/wpfxm.nix { });
  nixup = withRustNative (super.callPackage ./pkgs/nixup.nix { });
  nixos-update-status = withRustNative (super.callPackage ./pkgs/nixos-update-status.nix { });

  dxvk = super.callPackage ./pkgs/dxvk.nix { };
}
