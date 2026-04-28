pkgs: with pkgs; [
  bash
  coreutils

  glibc_multi.static

  sudo
  file
  lsof

  rsync
  dbus
  systemd
  pulseaudio

  libglvnd
  mesa
  mesa_glu

  wine # 32-bit & 64-bit on x86_64-linux, else 32-bit
]
