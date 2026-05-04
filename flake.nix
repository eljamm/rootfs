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
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        # nix build .#image-name
        images = import ./nix/images.nix { inherit pkgs; };

        # nix run .#image-name-tarball
        tarball-scripts = import ./nix/tarballs.nix { inherit images pkgs lib; };
      in
      {
        packages = images // tarball-scripts;
      }
    );
}
