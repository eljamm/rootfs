{
  pkgs64,
  pkgs32,
  lib,
  type,
}:

assert lib.elem type [
  "minimal"
  "full"
];

let
  types = {
    minimal = {
      pkgs64 = with pkgs64; [
        bash
        coreutils

        # system
        sudo
        file
        lsof
        polkit
        rsync
        lsb-release
        glibc_multi.static
        dbus
        systemd
        glibcLocales
        fuse2
        openssl
        curl
        xz
        python3
        libselinux
        apt

        # audio
        pulseaudio
        openal
        speex
        libvorbis
        alsa-plugins

        # other
        protobuf
        protobufc
        libxcb
        xcb-util-cursor
        xcb-imdkit
        libxcb-image
        libxcb-keysyms
        libxcb-wm
        libxkbcommon
      ];

      pkgs32 = with pkgs32; [ ];
    };

    full = {
      pkgs64 =
        types.minimal.pkgs64
        ++ (with pkgs64; [
          # multimedia
          SDL
          SDL2
          libjpeg_turbo
          harfbuzz

          # graphics
          mesa
          mesa_glu
          libglvnd
          glew
          mesa-demos
          vulkan-tools
          libvdpau
          libva
          llvm
          clinfo
        ])
        # These packages are only available on x86_64 hosts because they also
        # need i686 packages, which can't be accessed when cross-compiling
        ++ lib.optionals (pkgs64.stdenv.buildPlatform.isx86) (
          with pkgs64;
          [
            mangohud
            winePackages.base
          ]
        );

      pkgs32 = types.minimal.pkgs32 ++ (with pkgs32; [ ]);
    };
  };
in
types.${type}.pkgs64 ++ types.${type}.pkgs32
