{
  pkgs,
  lib,
  nix2container,
}:

let
  baseImages = lib.mapAttrsRecursiveCond (value: !(value ? "imageName")) (
    _name: value: nix2container.pullImage value
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

    nix2container.buildImage {
      name = name;
      tag = "latest";
      fromImage = baseImage;
      copyToRoot = basePackages ++ packages;
      config = {
        entrypoint = [ "${pkgs.bash}/bin/bash" ];
      };
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
