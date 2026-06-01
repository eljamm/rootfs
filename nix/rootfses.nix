{
  pkgs,
  lib,
}:

let
  mkTarball =
    {
      name,
      type,
    }:

    let
      fhsEnv = pkgs.buildFHSEnvBubblewrap {
        name = name;
        targetPkgs = _:
          import ./packages.nix { inherit pkgs lib type; };
      };
    in

    pkgs.runCommand name
      {
        nativeBuildInputs = with pkgs; [
          libarchive
        ];
      }
      ''
        set -e
        mkdir -p "$out"
        bsdtar -czf "$out/${name}.tar.gz" \
          --exclude=nix-support \
          -C "${fhsEnv.fhsenv}" .
        echo "Done: $out/${name}.tar.gz"
      '';
in

{
  nix-rootfs = mkTarball {
    name = "nix-rootfs";
    type = "full";
  };
  ubuntu-rootfs = mkTarball {
    name = "ubuntu-rootfs";
    type = "full";
  };
}
