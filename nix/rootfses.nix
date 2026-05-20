{
  images,
  pkgs,
  lib,
}:

let
  mkTarball =
    image:
    pkgs.runCommand "create-${image.imageName}-rootfs" { } ''
      set -e

      IMAGE_NAME="${image.imageName}"
      OUTPUT_FILE="''${1:-$IMAGE_NAME.tar.gz}"

      echo "Creating $OUTPUT_FILE"

      echo "Loading OCI image into Docker"
      docker load < ${image}

      echo "Creating temporary container"
      CONTAINER_ID="$(docker create --name "$IMAGE_NAME" "$IMAGE_NAME")"

      echo "Exporting rootfs to $OUTPUT_FILE"
      docker export "$CONTAINER_ID" | ${pkgs.libarchive}/bin/bsdtar -czf - \
        --exclude=media --exclude=mnt --exclude=root --exclude=srv \
        --exclude=boot --exclude=home --exclude=run --exclude=proc \
        --exclude=sys --exclude=dev --exclude=tmp --exclude=.dockerenv \
        @- > "$OUTPUT_FILE"

      echo "Removing temporary container"
      docker rm "$CONTAINER_ID"

      echo "Done!"
    '';
in

lib.mapAttrs' (name: value: lib.nameValuePair (name + "-rootfs") (mkTarball value)) images
