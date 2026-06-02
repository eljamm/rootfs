{
  description = "felix86 x86/x86_64 rootfs built with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        n2c = inputs.nix2container.packages.${system};

        # nix build .#image-name
        images = import ./nix/images.nix { inherit pkgs lib n2c; };

        # nix build .#image-name-rootfs
        rootfs-scripts = import ./nix/rootfses.nix { inherit pkgs lib images; };

        # nix build .#build-all
        build-all = pkgs.runCommand "build-rootfs-all" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: _: ''
              ln -s "${rootfs-scripts.${name}}/${name}.tar.gz" "$out/${name}.tar.gz"
            '') rootfs-scripts
          )}
        '';

        felix86 =
          # try using native felix if available on platform, else emulate it
          if lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.felix86 then
            pkgs.felix86
          else
            pkgs.writeShellApplication {
              name = "felix86";
              runtimeInputs = with pkgs; [
                qemu
                pkgsCross.riscv64.felix86
              ];
              text = ''
                FELIX86_PATH=$(type -p felix86)
                qemu-riscv64 -cpu max,vlen=256 "$FELIX86_PATH" "$@"
              '';
            };

        # WIP:
        env =
          (pkgs.buildFHSEnvBubblewrap {
            name = "fhs-rootfs";
            version = "0.1.0";
            targetPkgs =
              pkgs:
              import ./nix/packages.nix {
                inherit pkgs;
                lib = pkgs.lib;
                type = "full";
              };
          }).fhsenv;

        oci = pkgs.writeShellScriptBin "build-oci-images" ''
          ${images.default.copyTo}/bin/copy-to oci-archive:./felix86-oci.tar:latest
          echo "Created container image in ./felix86-oci.tar"
        '';

        oci2 = pkgs.writeShellScriptBin "build-rootfs-tarball" ''
          export PATH="${
            pkgs.lib.makeBinPath [
              pkgs.umoci
              pkgs.gnutar
              pkgs.gzip
            ]
          }:$PATH"

          echo "Building OCI layout folder..."
          # nix2container's copyTo can output directly to an uncompressed oci directory structure
          ${images.default.copyTo}/bin/copy-to oci:./felix86-oci-layout:latest

          echo "Unpacking rootfs via umoci..."
          umoci unpack --rootless --image ./felix86-oci-layout:latest ./unpacked-rootfs

          echo "Creating compressed tarball..."
          tar -czf ./felix86-rootfs.tar.gz -C ./unpacked-rootfs/rootfs .

          # Clean up temporary layouts
          rm -rf ./felix86-oci-layout ./unpacked-rootfs
          echo "Successfully created flat rootfs in ./felix86-rootfs.tar.gz"
        '';
      in
      {
        packages = {
          inherit
            build-all
            env
            oci
            oci2
            ;
        }
        // images
        // rootfs-scripts;

        # nix develop
        devShell = pkgs.mkShell {
          packages = [
            felix86
          ];
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
