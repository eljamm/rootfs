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
        fakeroot
        gnutar
        umoci
      ];
      text = ''
        set -e

        TMPDIR=$(mktemp -d)

        cleanup() {
          # links to Nix store must be writable, otherwise they can't be removed
          [[ -d "$TMPDIR" ]] && chmod -R +w "$TMPDIR" 2>/dev/null || true
          rm -rf "$TMPDIR"
        }
        trap cleanup EXIT

        IMAGE_NAME="${image.imageName}"
        IMAGE_TAG="${image.imageTag}"

        echo "Unpacking $IMAGE_NAME:$IMAGE_TAG image"
        pushd "$TMPDIR"
        mkdir -p oci-layout unpacked

        # copy image to an OCI-layout directory
        ${image.copyTo}/bin/copy-to oci:./oci-layout:$IMAGE_TAG

        umoci unpack --rootless --image ./oci-layout:$IMAGE_TAG ./unpacked
        popd

        ROOTFS_PATH="./rootfs-$IMAGE_NAME"
        TARGET_PATH="$ROOTFS_PATH"

        if [[ -d "$ROOTFS_PATH" ]]; then
            counter=1
            # loop until we find a suffix number that doesn't exist, yet
            while [[ -d "''${ROOTFS_PATH}_''${counter}" ]]; do
                ((counter++))
            done
            TARGET_PATH="''${ROOTFS_PATH}_''${counter}"
        fi

        echo "Creating rootfs in $TARGET_PATH"
        cp -a "$TMPDIR"/unpacked/rootfs "$TARGET_PATH"
        fakeroot chown -R root:root "$TARGET_PATH"

        echo "Writing rootfs tarball to $IMAGE_NAME.tar.gz"
        tar \
          --owner=0 \
          --group=0 \
          -czf "$IMAGE_NAME.tar.gz" \
          -C "$TARGET_PATH" \
          .
      '';
    };
in

# convert all OCI artefacts into scripts that generate compressed tarballs
lib.mapAttrs' (name: value: lib.nameValuePair (name + "-rootfs") (mkTarball value)) images
