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
        lib = args.pkgs.lib;
        n2c = inputs.nix2container.packages.${system};

        args = { inherit pkgs lib n2c; };

        # nix build .#image-name
        images = import ./nix/images.nix args;

        # nix build .#image-name-rootfs
        rootfs-scripts = import ./nix/rootfses.nix (args // { inherit images; });
      in
      {
        formatter = pkgs.nixfmt-tree;

        # nix develop
        devShell = import ./nix/devshell.nix args;

        packages = {
          # nix build .#rootfs-all
          rootfs-all = pkgs.runCommand "build-rootfs-all" { } ''
            mkdir -p $out

            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (name: _: ''
                ln -s "${rootfs-scripts.${name}}/${name}.tar.gz" "$out/${name}.tar.gz"
              '') rootfs-scripts
            )}
          '';
        }
        // images
        // rootfs-scripts;
      }
    );
}
