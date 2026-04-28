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
                  "/etc"
                  "/lib"
                  "/lib64"
                  "/sbin"
                ];
              })
            ];
          };

        baseImages = import ./nix/base-images.nix;

        ubuntuBase = pkgs.dockerTools.pullImage baseImages.ubuntu."24_04";
        fedoraBase = pkgs.dockerTools.pullImage baseImages.fedora."43";

        images-raw = {
          felix86 = {
            name = "felix86";
            packages = import ./nix/packages.nix pkgs;
          };
          felix86-ubuntu = {
            name = "felix86-ubuntu";
            baseImage = ubuntuBase;
            packages = images-raw.felix86.packages;
          };
          felix86-fedora = {
            name = "felix86-fedora";
            baseImage = fedoraBase;
            packages = images-raw.felix86.packages;
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
          felix86-ubuntu-tarball = mkTarball images.felix86-ubuntu;
          felix86-fedora-tarball = mkTarball images.felix86-fedora;
        };

        mkRootfs = import ./nix/mk-rootfs.nix { inherit pkgs lib; };

        rootfses = {
          rootfs-ubuntu = mkRootfs {
            name = "rootfs-ubuntu";
            baseImage = ubuntuBase;
            packages = images-raw.felix86.packages;
          };
          rootfs-fedora = mkRootfs {
            name = "rootfs-fedora";
            baseImage = fedoraBase;
            packages = images-raw.felix86.packages;
          };
        };

        mkRootfsTarball =
          rootfs:
          pkgs.runCommand "${rootfs.name}-tarball" { } ''
            tar -czf $out -C ${rootfs} .
          '';

        tarballs = lib.mapAttrs' (
          name: value: lib.nameValuePair (name + "-tarball") (mkRootfsTarball value)
        ) rootfses;
      in
      {
        packages = tarballs // rootfses // images // rootfs-scripts;
      }
    );
}
