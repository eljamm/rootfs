{
  pkgs,
  lib,
  n2c,
  ...
}:

let
  mkImage =
    {
      name,
      extraPackages,
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

      rootEnv =
        # Construct an FHS environment that follows UsrMerge
        # See: https://www.freedesktop.org/wiki/Software/systemd/TheCaseForTheUsrMerge
        (pkgs.buildFHSEnv {
          name = "felix86-fhs-env";
          targetPkgs = _: basePackages ++ extraPackages;
        }).fhsenv;

      container = n2c.nix2container.buildImage {
        name = name;
        tag = "latest";
        copyToRoot = rootEnv;
        config = {
          entrypoint = [ "${pkgs.bash}/bin/bash" ];
        };
      };
    in

    container.overrideAttrs (
      _final: prev: {
        passthru = prev.passthru // {
          # Include envrionment for debugging:
          #   nix build .#image-name.rootEnv
          inherit rootEnv;
        };
      }
    );
in

{
  default = mkImage {
    name = "felix86";
    type = "full";
    extraPackages = with pkgs; [ ];
  };
}
