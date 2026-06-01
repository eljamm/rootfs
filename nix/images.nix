{
  pkgs,
  lib,
  nix2container,
}:

let
  mkImage =
    {
      name,
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
      copyToRoot = basePackages ++ packages;
      config = {
        entrypoint = [ "${pkgs.bash}/bin/bash" ];
      };
    };
in

{
  nix = mkImage {
    name = "nix";
    packages = [ ];
    type = "full";
  };
  ubuntu = mkImage {
    name = "ubuntu";
    packages = [ ];
    type = "full";
  };
}
