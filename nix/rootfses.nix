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
        targetPkgs = _: import ./packages.nix { inherit pkgs lib type; };
      };
    in

    pkgs.runCommand name
      {
        nativeBuildInputs = with pkgs; [
          libarchive
          rsync
          fakeroot
          rdfind
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

        # 2. Fix absolute symlinks to relative (rsync-safe)
        #    e.g.  bin        -> /usr/bin   →  bin        -> usr/bin
        #          usr/lib    -> /usr/lib64 →  usr/lib    -> lib64
        #          usr/lib64/ld-linux.so.2 -> /usr/lib32/ld-linux.so.2
        #                                →  usr/lib64/ld-linux.so.2 -> ../lib32/ld-linux.so.2
        find "$SRC" -type l | while read link; do
          target=$(readlink "$link")
          case "$target" in
            /usr/*|/bin/*|/lib/*|/sbin/*|/etc/*)
              rel=$(realpath -s --relative-to="$(dirname "$link")" "$SRC$target")
              ln -sfn "$rel" "$link"
              ;;
          esac
        done

        # 3. Selectively resolve: preserve safe symlinks,
        #    dereference Nix store symlinks to actual files
        mkdir -p "$out"
        ${pkgs.fakeroot}/bin/fakeroot bash -c '
          rsync -a --copy-unsafe-links "'"$SRC"'/" "'"$DST"'/"

          # 4a. Strip runtime-unnecessary files
          # Static libraries — useless outside of compilation
          find "'"$DST"'" -name "*.a" -delete
          # LLVM profiling tool — not needed at runtime
          rm -f "'"$DST"'/usr/bin/llvm-exegesis"
          # Python test/idle data
          rm -rf "'"$DST"'"/usr/lib*/python3.*/test
          rm -rf "'"$DST"'"/usr/lib*/python3.*/idlelib
          rm -rf "'"$DST"'"/usr/lib*/python3.*/__pycache__
          find "'"$DST"'" -name "*.pyc" -o -name "*.pyo" -delete
          # Documentation — not needed at runtime
          rm -rf "'"$DST"'"/usr/share/man
          rm -rf "'"$DST"'"/usr/share/doc
          rm -rf "'"$DST"'"/usr/share/info
          # Locales — keep only essential (or none)
          rm -f "'"$DST"'/usr/lib64/locale/locale-archive"
          # GConf schemas cache — will be regenerated at runtime
          rm -f "'"$DST"'/usr/share/GConf/gsettings.xml"
          rm -f "'"$DST"'/usr/share/glib-2.0/schemas/gschemas.compiled"

          # 4b. Hardlink identical files (fix rsync-broken hardlinks)
          rdfind -makehardlinks true "'"$DST"'" > /dev/null 2>&1 || true

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
