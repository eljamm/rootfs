{
  pkgs,
  lib,
}:

let
  # recursively pull leaf base images
  baseImages = lib.mapAttrsRecursiveCond (value: !(value ? "imageName")) (
    _name: value: pkgs.dockerTools.pullImage value
  ) (import ./base-images.nix);

  mkImage =
    {
      name,
      baseImage ? null,
      packages,
      type,
    }:

    assert lib.elem type [
      "minimal"
      "full"
    ];

    let
      basePackages = import ./packages.nix {
        inherit pkgs lib type;
      };
    in

    pkgs.dockerTools.buildLayeredImage {
      name = name;
      tag = "latest";
      fromImage = baseImage;
      contents = basePackages ++ packages;
      # WARN: only disable when debugging, else the resulting rootfs will not
      # be self-contained
      includeStorePaths = false;
    };
in

{
  nix = mkImage {
    name = "nix";
    baseImage = baseImages.nix."2.32.8";
    packages = [ ];
    type = "full";
  };
  ubuntu = mkImage {
    name = "ubuntu";
    baseImage = baseImages.ubuntu."24_04";
    packages = [ ];
    type = "full";
  };
}
