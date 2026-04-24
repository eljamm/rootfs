{
  description = "felix86 x86_64 rootfs built with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        mkImage =
          {
            name,
            baseImage ? null,
            packages,
          }:
          pkgs.dockerTools.buildLayeredImage {
            name = name;
            tag = "latest";
            fromImage = baseImage;
            contents = [
              (pkgs.buildEnv {
                name = "fhs-rootfs";
                paths = packages;
                pathsToLink = [
                  "/bin"
                  "/lib"
                  "/etc"
                ];
              })
            ];
          };

        # TODO: refactor

        baseImages = import ./nix/base-images.nix;

        ubuntuBase = pkgs.dockerTools.pullImage baseImages.ubuntu."24_04";
        fedoraBase = pkgs.dockerTools.pullImage baseImages.fedora."43";

        images-raw = {
          hello = {
            name = "hello";
            packages = with pkgs; [
              bash
              coreutils
              hello
            ];
          };
          hello-ubuntu = {
            name = "hello-ubuntu";
            baseImage = ubuntuBase;
            packages = images-raw.hello.packages;
          };
          hello-fedora = {
            name = "hello-fedora";
            baseImage = fedoraBase;
            packages = images-raw.hello.packages;
          };
        };

        # nix build .#image-name
        images = lib.mapAttrs (name: mkImage) images-raw;

        # NOTE:
        # this script generates the tarball image ** at runtime **
        mkTarball =
          image:
          pkgs.writeShellScriptBin "create-image-tarball" ''
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

        # nix run .#script-name
        rootfs-scripts = {
          hello-ubuntu-tarball = mkTarball images.hello-ubuntu;
          hello-fedora-tarball = mkTarball images.hello-fedora;
        };
      in
      {
        packages = images // rootfs-scripts;
      }
    );
}
