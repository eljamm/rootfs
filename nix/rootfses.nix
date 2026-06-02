{
  images,
  pkgs,
  lib,
  ...
}:

let
  mkTarball =
    image:

    pkgs.writeShellApplication {
      name = image.imageName;
      runtimeInputs = with pkgs; [
        gnutar
        umoci
      ];
      text = ''
        set -e

        TMPDIR=$(mktemp -d)

        IMAGE_NAME="${image.imageName}"
        IMAGE_TAG="${image.imageTag}"

        echo "Unpacking $IMAGE_NAME:$IMAGE_TAG image"
        pushd "$TMPDIR"
        mkdir -p oci-layout unpacked

        # copy image to an OCI-layout directory
        ${image.copyTo}/bin/copy-to oci:./oci-layout:$IMAGE_TAG

        umoci unpack --rootless --image ./oci-layout:$IMAGE_TAG ./unpacked
        popd

        echo "Creating $IMAGE_NAME.tar.gz"
        tar \
          --owner=0 \
          --group=0 \
          -czf "$IMAGE_NAME.tar.gz" \
          -C "$TMPDIR"/unpacked/rootfs \
          .
      '';
    };
in

# convert all OCI artefacts into scripts that generate compressed tarballs
lib.mapAttrs' (name: value: lib.nameValuePair (name + "-rootfs") (mkTarball value)) images
