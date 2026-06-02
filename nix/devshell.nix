{
  pkgs,
  lib,
  ...
}:

let
  felix86Emulated = pkgs.writeShellApplication {
    name = "felix86";
    runtimeInputs = with pkgs; [
      qemu
      pkgsCross.riscv64.felix86
    ];
    text = ''
      FELIX86_PATH=$(type -p felix86)
      qemu-riscv64 -cpu max,vlen=256 "$FELIX86_PATH" "$@"
    '';
  };

  felix86 =
    # use native felix if available on platform, else emulate it with QEMU
    if lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.felix86 then
      pkgs.felix86
    else
      felix86Emulated;
in

pkgs.mkShell {
  packages = [
    felix86
  ];
}
