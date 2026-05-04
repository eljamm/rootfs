{
  images,
  pkgs,
  lib,
}:

let
  mkTarball =
    image:
    # NOTE:
    # this script generates the tarball image ** at runtime **
    pkgs.writeShellScriptBin "create-${image.imageName}-tarball" ''
      IMAGE_NAME="${image.imageName}"
      OUTPUT_FILE="''${1:-$IMAGE_NAME.tar.gz}"

      echo "Creating $OUTPUT_FILE"

      echo "Loading OCI image into Docker"
      docker load < ${image}

      echo "Creating temporary container"
      CONTAINER_ID="$(docker create "$IMAGE_NAME")"

      echo "Exporting rootfs to $OUTPUT_FILE"
      docker export "$CONTAINER_ID" | gzip > "$OUTPUT_FILE"

      echo "Removing temporary container"
      docker rm "$CONTAINER_ID"

      echo "Done!"
    '';
in

lib.mapAttrs' (name: value: lib.nameValuePair (name + "-tarball") (mkTarball value)) images
