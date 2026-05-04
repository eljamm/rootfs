{
  pkgs,
  lib,
}:

let
  # recursively pull leaf base images
  baseImages = lib.mapAttrsRecursiveCond (value: value ? "imageName") (
    _name: value: pkgs.dockerTools.pullImage value
  ) (import ./nix/base-images.nix);

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

  commonPackages = import ./packages.nix pkgs;
in

{
  ubuntu = mkImage {
    name = "ubuntu";
    baseImage = baseImages.ubuntu;
    packages = commonPackages;
  };
  fedora = mkImage {
    name = "fedora";
    baseImage = baseImages.fedora;
    packages = commonPackages;
  };
}
