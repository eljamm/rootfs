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

          # WoW64 wine works on both native and cross x86_64 builds. Also see:
          # - https://wiki.nixos.org/wiki/Wine
          # - https://wiki.archlinux.org/title/Wine#32-bit_Windows_applications
          wineWow64Packages.stable

          (mangohud.override {
            pkgsi686Linux = pkgs32;
          })
        ]);

      pkgs32 =
        types.minimal.pkgs32
        ++ (with pkgs32; [
        ]);
    };
  };
in
types.${type}.pkgs64 ++ types.${type}.pkgs32
