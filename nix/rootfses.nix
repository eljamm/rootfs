{
  images,
  pkgs,
  lib,
}:

let
  mkTarball =
    image:

    pkgs.runCommand image.imageName
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
        ${image.copyTo}/bin/copy-to oci:oci-layout:latest

        # unpack image
        umoci unpack --rootless --image ./oci-layout:latest ./unpacked

        # compress
        tar -c -C ./unpacked/rootfs . | gzip > "$out/${image.imageName}.tar.gz"
      '';
in

# convert all OCI artefacts into compressed tarballs
lib.mapAttrs' (name: value: lib.nameValuePair (name + "-rootfs") (mkTarball value)) images
