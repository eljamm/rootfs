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

        # nix run nixpkgs#nix-prefetch-docker -- --image-name ubuntu --image-tag 24.04
        ubuntuBase = pkgs.dockerTools.pullImage {
          imageName = "ubuntu";
          imageDigest = "sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b";
          hash = "sha256-4fNRgZzYvIKgzdJDOK5IH5fBkmzQQNMIDAEVoQj56Uk=";
          finalImageName = "ubuntu";
          finalImageTag = "24.04";
        };
      in
      {
        # nix build .#hello-image
        packages.hello-image =
          let
            rootfsPackages = with pkgs; [
              bash
              coreutils
              hello
            ];

            fhsEnv = pkgs.buildEnv {
              name = "fhs-rootfs";
              paths = rootfsPackages;
              pathsToLink = [
                "/bin"
                "/lib"
                "/etc"
              ];
            };
          in
          pkgs.dockerTools.buildLayeredImage {
            name = "hello-ubuntu";
            tag = "latest";

            fromImage = ubuntuBase;
            contents = [ fhsEnv ];

            config = {
              Cmd = [ "${pkgs.hello}/bin/hello" ];
              Env = [ "PATH=/bin" ];
            };
          };

        # NOTE:
        # this script generates the tarball image ** at runtime **
        #
        # nix run .#hello-tarball
        packages.hello-tarball =
          let
            image = self.packages.${system}.hello-image;
          in
          pkgs.writeShellScriptBin "create-rootfs" ''
            IMAGE_NAME="${image.imageName}"
            OUTPUT_FILE="''${1:-$IMAGE_NAME.tar.gz}"

            echo "Loading OCI image into Docker"
            docker load < ${image}

            echo "Creating temporary container"
            CONTAINER_ID="$(docker create "$IMAGE_NAME")"

            echo "Exporting rootfs to $OUTPUT_FILE"
            docker export "$CONTAINER_ID" | gzip > "$OUTPUT_FILE"

            echo "Removing temporary container"
            docker rm "$CONTAINER_ID"

            echo "Done! Rootfs saved to $OUTPUT_FILE"
          '';
      }
    );
}
