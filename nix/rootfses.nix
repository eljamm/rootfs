{
  images,
  pkgs,
  lib,
}:

let
  mkTarball =
    {
      name,
      baseImage,
    }:

    pkgs.runCommand name
      {
        nativeBuildInputs = with pkgs; [
          gnutar
          umoci
          writableTmpDirAsHomeHook
        ];
      }
      ''
        mkdir -p oci-layout unpacked

        # copy image to OCI layout directory
        ${baseImage.copyTo}/bin/copy-to oci:oci-layout:latest

        # unpack image
        umoci unpack --rootless --image ./oci-layout:latest ./unpacked

        # compress
        tar -c -C ./unpacked/rootfs . | gzip > "$out/${name}.tar.gz"
      '';
in

{
  default-rootfs = mkTarball {
    name = "felix86-rootfs";
    baseImage = images.default;
  };
}
