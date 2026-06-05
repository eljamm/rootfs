{
  pkgsNative,
  lib,
  system,
  ...
}:

let
  # native if on x86_64/x86, cross-compiled otherwise
  pkgs64 =
    if system == "x86_64-linux" then
      pkgsNative
    else
      pkgsNative.pkgsCross.gnu64.extend (
        _final: _prev: {
          # On non-x86 hosts, pkgsi686Linux is defined as "32-bit version of
          # the host architecture" [^1], so on RISC-V you'd get 32-bit RISC-V,
          # not 32-bit x86.
          #
          # Here, we replace it with a cross-compiled i686 set, such that the
          # result is always 32-bit x86, independent of the host architecture.
          #
          # This is needed by packages like mangohud and non-WoW64 wine,
          # which require both x86_64 and i686 components.
          #
          # ---
          # [^1]: https://github.com/NixOS/nixpkgs/blob/1c117f5aff5200b7648587e05eb74c0c340211f2/pkgs/top-level/stage.nix#L214
          pkgsi686Linux = pkgsNative.pkgsCross.gnu32;
        }
      );
  pkgs32 = if system == "x86_64-linux" then pkgsNative.pkgsi686Linux else pkgsNative.pkgsCross.gnu32;

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
        inherit
          lib
          type
          pkgs64
          pkgs32
          ;
      };

      rootEnv =
        # Construct an FHS environment that follows UsrMerge. See:
        # - https://github.com/NixOS/nixpkgs/blob/master/doc/build-helpers/special/fhs-environments.section.md
        # - https://www.freedesktop.org/wiki/Software/systemd/TheCaseForTheUsrMerge
        pkgsNative.buildFHSEnv {
          name = "${name}-fhs-env";
          targetPkgs = _: basePackages ++ extraPackages;
        };

      rootFHS = rootEnv.fhsenv;
    in
    pkgsNative.stdenv.mkDerivation {
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
    extraPackages = with pkgsNative; [ ];
  };
}
