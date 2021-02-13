self: super:

{
  # Latest Wine staging with Proton patches from GloriousEggroll.
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
    version = "6.1";
    geVersion = "${version}-GE-1";

    src = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      rev = "wine-${version}";
      sha256 = "fcb+r8kFAmr1xUNi2KuBurTXrs9B/T7KKMRq/XWtjHk=";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "5c5a8f3b2cf49b5aefcc8f63061e8030e8ca0294";
      sha256 = "pulZfHhpGji/LFoWVAghTyHBSbl+BrbFddQfrMyg+K8=";
    };

    # Temp
    patches = [];

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    repoPath = path: sha256: super.fetchurl {
      url = "https://raw.githubusercontent.com/GloriousEggroll/proton-ge-custom/${drv.geVersion}/${path}";
      inherit sha256;
    };

    patchAbsPath = path: repoPath "${path}.patch";

    patch = name: patchAbsPath "patches/${name}";
    hotfix = name: patch "wine-hotfixes/${name}";
  in {
    name = "wine-wow-${drv.version}-staging-ge";

    nativeBuildInputs = drv.nativeBuildInputs ++ [
      super.git
      super.perl
      super.utillinux
      super.autoconf
      super.python3
      super.perl
    ];

    protonPatches = let
      game = name: patch "game-patches/${name}";
      proton = name: patch "proton/${name}";

      # Need this for VK_VALVE_mutable_descriptor extension
      vulkanPatch = super.fetchurl {
        name = "proton-winevulkan-nofshack.patch";
        url = "https://raw.githubusercontent.com/Frogging-Family/wine-tkg-git/a3748826bb3d1696faf2585b7bf662ac6f1fa7d8/wine-tkg-git/wine-tkg-patches/proton/proton-winevulkan-nofshack.patch";
        sha256 = "KkTkoHveGI+Qjjhimz0/vcvX/QPaLUl1e1jz/lRWvBA=";
      };

      fsync2 = super.fetchurl {
        name = "fsync2.patch";
        url = "https://raw.githubusercontent.com/Frogging-Family/community-patches/master/wine-tkg-git/fsync_futex2.mypatch";
        sha256 = "PNnhENrDUVePM4LAPoBYONKPS0eFktvf9UIOLoClONU=";
      };
    in [
      (hotfix "imm32-com-initialization_no_net_active_window" "gPEkiO34ZYMmQugg+nR2lgAPt842dPXQJwej8l5PSuw=")

      (proton "01-proton-use_clock_monotonic" "63Yzm2tJNJmarDo0MXi/TRdKJi7vYFz+BQL1d03js9c=")
      (proton "03-proton-fsync_staging" "Qrt7/hCaH25Mlcf7kItvpAG/DQ25VGdVbnk87eDSxB8=")
      fsync2
      (proton "04-proton-LAA_staging" "DxWXCWI4MCSA6rLTn+yEXtcIRP1qOCbGBwCltVP9XC0=")
      (proton "10-proton-protonify_staging" "a3cZm13vK7b5xcIS2ytMcqSa2NC7dwD8WP7NS3fes+U=")
      (proton "11-proton-pa-staging" "csc5wD6aSo/JlvxuOYwrJ+RIVeEQi4r0r6fqCyHusBQ=")
      #(proton "15-proton-gamepad-additions" "1wISrj8sE8480ZPVUQhPudSrfBSUoBkglPVyJnyaCkg=")
      (proton "02-proton-FS_bypass_compositor" "oQMpsuw1WYHOezPwD/ru/sBeurISFB2tdTa93LIXHFk=")
      vulkanPatch
      (proton "18-proton-amd_ags" "JhJc7DygOmzVUUBxt9/PnKGdJ36jCj03YhCR4N1J83E=")
      #(proton "19-proton-msvcrt_nativebuiltin" "9tfc3TM8ZA3tadFv5wmhY+6GvW70fJuJupWfQh76A0Q=")
      #(proton "20-proton-atiadlxx" "TY2ir2b1wyzdBFn1xQUcqbar/Ro/+l4VWxpQUnUHyR4=")
      (proton "25-proton-rdr2-fixes" "dz0kqC5BWEOFZsvpCvLcKLCY+/n51dJ2an1VRCujHe4=")

      (hotfix "winevulkan-childwindow" "5nDvZUILS4yQ4OiXXkemK1kWzMB8YGA9AEbhf2BIjdg=")
      (hotfix "0033-HACK-Switch-between-all-selection-streams-on-MF_SOUR" "6eh46fN0eH7wUCHDNGfVHPRnDmRTnUYfA/kOf2+/s6s=")
      (hotfix "198992" "JJZWeR6D9Ekz0U8YlRYs0vvLRbb1ZxsUUZ5bg9eEpIo=")
    ];

    preStagingPatches = [
      (hotfix "mfplat_rebase_staging_6.1" "wXgh+rS8GGnrAM/IeMs/HcoN04ZLC/tZhQ5dLyLo+7M=")
    ];

    reverts = let
      commit = hash: sha256: super.fetchurl {
        url = "https://github.com/wine-mirror/wine/commit/${hash}.patch";
        inherit sha256;
      };
    in [
      (commit "bd27af974a21085cd0dc78b37b715bbcc3cfab69" "fmxVQe7cWN2Ffsu3jKAMmV6r7Cp5sgbsJ3Ca3iN09Ls=")
      (commit "1fceb1213992b79aa7f1a5dc0a72ab3756ee524d" "DD5mbrunUu++7lN4hPudaWWGE/sGd10TNdtoVW3oeXg=")
      (commit "e4fbae832c868e9fcf5a91c58255fe3f4ea1cb30" "V47itrSHnA7Jf/F/hYnMiw1fv12TKSXcqJC855z/GAI=")
    ];

    postPatch =
      let
        vulkanVersion = "1.2.168";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "6YrG0vMr7kri/HWqPMCb3Xm/2CWmMGSHF/zTbO7Oc5U=";
        };
      in ''
        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w -R patches/

        for revert in $reverts; do
          echo "!! applying revert ''${revert}"
          patch -NRp1 < "$revert"
        done

        for patch in $preStagingPatches; do
          echo "!! applying pre-staging patch ''${patch}"
          patch -Np1 < "$patch"
        done

        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all \
          -W winex11-_NET_ACTIVE_WINDOW \
          -W winex11-WM_WINDOWPOSCHANGING \
          -W imm32-com-initialization \
          -W kernel32-SetProcessDEPPolicy
        cd ..

        echo "applying Proton patches.."

        for patch in $protonPatches; do
          echo "!! applying ''${patch}"
          patch -Np1 < "$patch"
        done

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
}