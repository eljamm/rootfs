{
  pkgs,
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
      pkgs64 = with pkgs; [
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

      pkgs32 = with pkgs.pkgsi686Linux; [
      ];
    };

    full = {
      pkgs64 = with pkgs; [
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

        # gaming
        mangohud
        winePackages.base # 32-bit & 64-bit on x86_64-linux, else 32-bit
      ];

      pkgs32 = with pkgs.pkgsi686Linux; [
      ];
    };
  };
in
with types.${type};
pkgs64 ++ pkgs32
