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
      contents =
        (pkgs.buildFHSEnvBubblewrap {
          name = "felix86-fhs-env";
          targetPkgs = _: basePackages ++ packages;
        }).fhsenv;

      # WARN: only disable when debugging, else the resulting rootfs will not
      # be self-contained
      includeStorePaths = true;

      # enableFakechroot = true;
      # fakeRootCommands =
      #   # bash
      #   ''
      #     # strip runtime-unnecessary files to reduce size (FHS + Nix store paths)
      #     find . -name "*.a" -delete
      #     find . -name "llvm-exegesis" -type f -delete
      #     find . -path "*/python3.*/test" -type d -prune -exec rm -rf {} + 2>/dev/null || true
      #     find . -path "*/python3.*/idlelib" -type d -prune -exec rm -rf {} + 2>/dev/null || true
      #     find . -name "__pycache__" -type d -prune -exec rm -rf {} + 2>/dev/null || true
      #     find . -name "*.pyc" -o -name "*.pyo" -delete
      #     find . -path "*/share/man" -type d -prune -exec rm -rf {} + 2>/dev/null || true
      #     find . -path "*/share/doc" -type d -prune -exec rm -rf {} + 2>/dev/null || true
      #     find . -path "*/share/info" -type d -prune -exec rm -rf {} + 2>/dev/null || true
      #     find . -name "locale-archive" -delete
      #     find . -name "gsettings.xml" -delete
      #     find . -name "gschemas.compiled" -delete
      #   '';

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
