pkgs: with pkgs; [
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

  # audio
  pulseaudio
  openal
  speex
  libvorbis
  alsa-plugins

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
  # removed from Nixpkgs (obsolete)
  #llvm_14
  #llvm_16
  llvm
  clinfo

  # gaming
  mangohud
  wine # 32-bit & 64-bit on x86_64-linux, else 32-bit

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

  # TODO: 32-bit
]
