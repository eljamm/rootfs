{
  images,
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
      packages = import ./packages.nix { inherit pkgs lib type; };
      fhsEnv = pkgs.buildFHSEnvBubblewrap {
        name = name;
        targetPkgs = _: packages;
      };
      closureInfo = pkgs.closureInfo { rootPaths = packages; };
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

        # 2. Fix absolute FHS symlinks to relative (rsync-safe).
        #    Leave /nix/store symlinks as-is — they'll resolve from the store closure.
        find "$SRC" -type l | while read link; do
          target=$(readlink "$link")
          case "$target" in
            /usr/*|/bin/*|/lib/*|/sbin/*|/etc/*)
              rel=$(realpath -s --relative-to="$(dirname "$link")" "$SRC$target")
              ln -sfn "$rel" "$link"
              ;;
          esac
        done

        mkdir -p "$out"
        ${pkgs.fakeroot}/bin/fakeroot bash -c '
          # 3. Copy fhsenv structure (preserving all symlinks — no --copy-unsafe-links)
          rsync -a "'"$SRC"'/" "'"$DST"'/"

          # 4. Include the Nix store closure so /nix/store symlinks resolve
          while IFS= read -r p; do
            [ -n "$p" ] && cp -a --parents "$p" "'"$DST"'/"
          done < "'${closureInfo}'/store-paths"
          chmod -R u+w "'"$DST"'"/nix

          # 5. Strip runtime-unnecessary files (both FHS and Nix store paths)
          find "'"$DST"'" -name "*.a" -delete
          find "'"$DST"'" -name "llvm-exegesis" -type f -delete
          find "'"$DST"'" -path "*/python3.*/test" -type d -exec rm -rf {} + 2>/dev/null || true
          find "'"$DST"'" -path "*/python3.*/idlelib" -type d -exec rm -rf {} + 2>/dev/null || true
          find "'"$DST"'" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
          find "'"$DST"'" -name "*.pyc" -o -name "*.pyo" -delete
          find "'"$DST"'" -path "*/share/man" -type d -exec rm -rf {} + 2>/dev/null || true
          find "'"$DST"'" -path "*/share/doc" -type d -exec rm -rf {} + 2>/dev/null || true
          find "'"$DST"'" -path "*/share/info" -type d -exec rm -rf {} + 2>/dev/null || true
          find "'"$DST"'" -name "locale-archive" -delete
          find "'"$DST"'" -name "gsettings.xml" -delete
          find "'"$DST"'" -name "gschemas.compiled" -delete

          # 6. Hardlink identical files (fix rsync-broken hardlinks)
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
