{
  pkgs,
  lib,
}:

let
  dockerTools = pkgs.dockerTools;

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

    dockerTools.buildLayeredImage {
      name = name;
      tag = "latest";
      contents = basePackages ++ packages;
      includeStorePaths = true;
      config = {
        Cmd = [ "${pkgs.bash}/bin/bash" ];
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
