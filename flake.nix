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
      nix2container,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        n2c = nix2container.packages.${system};

        # nix build .#image-name
        images = import ./nix/images.nix {
          inherit pkgs lib;
          nix2container = n2c.nix2container;
        };

        # nix build .#image-name-rootfs
        rootfs-scripts = import ./nix/rootfses.nix { inherit pkgs lib; };

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
      in
      {
        packages = {
          inherit build-all env;
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
