{
  pkgs,
  lib,
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

    pkgs.dockerTools.buildLayeredImage {
      name = name;
      tag = "latest";
      contents = basePackages ++ packages;

      # WARN: only disable when debugging, else the resulting rootfs will not
      # be self-contained
      includeStorePaths = false;

      enableFakechroot = true;
      fakeRootCommands = ''
        # TODO
      '';

      config = {
        Cmd = [ "${pkgs.bash}/bin/bash" ];
      };
    };
in

{
  default = mkImage {
    name = "felix86";
    packages = [ ];
    type = "full";
  };
}
