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
          rsync
          fakeroot
        ];
      }
      ''
        set -e
        SRC=$(mktemp -d)
        DST=$(mktemp -d)

        # 1. Copy fhsenv structure (preserving all symlinks)
        cp -r "${fhsEnv.fhsenv}"/* "$SRC/"

        # fhsenv files are read-only; make writable so we can fix symlinks
        chmod -R u+w "$SRC"

        # 2. Fix tree-internal absolute symlinks to relative
        #    e.g. bin -> /usr/bin  →  bin -> usr/bin
        #    These become "safe" for rsync --copy-unsafe-links
        find "$SRC" -type l | while read link; do
          target=$(readlink "$link")
          case "$target" in
            /usr/*|/bin/*|/lib/*|/sbin/*|/etc/*)
              ln -sf "''${target#/}" "$link"
              ;;
          esac
        done

        # 3. Selectively resolve: preserve safe symlinks,
        #    dereference Nix store symlinks to actual files
        mkdir -p "$out"
        ${pkgs.fakeroot}/bin/fakeroot bash -c '
          rsync -a --copy-unsafe-links "'"$SRC"'/" "'"$DST"'/"
          bsdtar -czf "'"$out/${name}.tar.gz"'" \
            --exclude=nix-support \
            -C "'"$DST"'" .
        '

        rm -rf "$SRC" "$DST"
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
