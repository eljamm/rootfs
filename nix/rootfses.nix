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
        set -e

        mkdir -p oci-layout unpacked $out

        # copy image to OCI layout directory
        ${image.copyTo}/bin/copy-to oci:./oci-layout:${image.imageTag}

        # unpack image
        umoci unpack --rootless --image ./oci-layout:${image.imageTag} ./unpacked

        # compress
        tar -czf "$out/${image.imageName}.tar.gz" -C ./unpacked/rootfs .
      '';
in

# convert all OCI artefacts into compressed tarballs
lib.mapAttrs' (name: value: lib.nameValuePair (name + "-rootfs") (mkTarball value)) images
