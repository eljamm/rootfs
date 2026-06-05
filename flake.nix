{
  description = "felix86 x86/x86_64 rootfs built with Nix";

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
    flake-utils.lib.eachSystem
      [
        "aarch64-linux"
        "riscv64-linux"
        "x86_64-linux"
      ]
      (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;

          rootfses = import ./nix/rootfses.nix {
            inherit lib system;
            pkgsNative = pkgs;
          };
        in
        {
          # nix fmt
          formatter = pkgs.nixfmt-tree;

          # nix develop
          devShell = import ./nix/devshell.nix { inherit pkgs lib; };

          packages = {
          }
          # nix build .#name
          // rootfses;
        }
      );
}
