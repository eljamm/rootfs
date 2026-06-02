{
  pkgs,
  lib,
  ...
}:

let
  mkRootfs =
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
        # Construct an FHS environment that follows UsrMerge. See:
        # - https://github.com/NixOS/nixpkgs/blob/master/doc/build-helpers/special/fhs-environments.section.md
        # - https://www.freedesktop.org/wiki/Software/systemd/TheCaseForTheUsrMerge
        pkgs.buildFHSEnv {
          name = "${name}-fhs-env";
          targetPkgs = _: basePackages ++ extraPackages;
        };

      rootFHS = rootEnv.fhsenv;
    in
    pkgs.stdenv.mkDerivation {
      name = "${name}-rootfs";

      # This tells Nix to compute the closure of the FHS env and write
      # the list of paths to a file named "graph". See:
      # https://nix.dev/manual/nix/2.34/language/advanced-attributes#adv-attr-exportReferencesGraph
      exportReferencesGraph = [
        "graph"
        rootEnv
      ];

      buildCommand =
        # bash
        ''
          mkdir -p $out/nix/store

          cp -R ${rootEnv.fhsenv}/. $out/

          # copy all FHS dependencies to the output's Nix store
          while read path; do
            # skip copying the env itself to prevent collisions
            if [[ "$path" == "${rootEnv}" ]]; then
              continue
            fi

            # copy store paths that don't already exist in output
            if [[ -e "$path" ]] && [[ ! -e "$out/nix/store/$(basename "$path")" ]]; then
              cp -a "$path" $out/nix/store/
            fi
          done < graph
        '';

      # nix build .#image-name.passthru.<name>
      passthru = {
        inherit
          rootEnv
          rootFHS
          ;
      };
    };
in

{
  default = mkRootfs {
    name = "felix86";
    type = "full";
    extraPackages = with pkgs; [ ];
  };
}
