{
  pkgs,
  lib,
}:

{
  name,
  baseImage,
  packages,
}:

let
  extractImage =
    image:
    pkgs.runCommand "extract-distro-rootfs"
      {
        nativeBuildInputs = with pkgs; [
          gnutar
          jq
        ];
      }
      ''
        mkdir -p $out
        TMPDIR=$(mktemp -d)

        extract_layers() {
          local excludes=$1

          exclude_args=()
          for e in "''${excludes[@]}"; do
              exclude_args+=(--exclude="$e")
          done

          layers="$(jq -r '.[0].Layers[]' "$TMPDIR"/manifest.json)"

          for layer in $layers; do
            tar --overwrite "''${exclude_args[@]}" -xf "$TMPDIR/$layer" -C $out 2>/dev/null || true
          done
        }

        tar -xf ${image} -C "$TMPDIR"

        excludes=(
          media mnt root srv
          boot home run proc
          sys dev tmp .dockerenv
        )

        extract_layers $excludes
      '';

  nixEnv = pkgs.buildEnv {
    name = "${name}-nix-env";
    paths = packages;
    pathsToLink = [
      "/bin"
      "/etc"
      "/lib"
      "/lib64"
      "/sbin"
      "/usr"
    ];
    ignoreCollisions = true;
  };
in

pkgs.runCommand "make-${name}"
  {
    nativeBuildInputs = with pkgs; [
      rsync
    ];
  }
  ''
    echo "Creating felix86 rootfs from ${baseImage.imageName} image ..."
    rsync -a --links ${extractImage baseImage}/ $out/

    chmod u+w $out/etc
    install -Dm644 ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-bundle.crt

    echo "Overlaying felix86 rootfs with Nix packages ..."
    rsync -a --copy-links --keep-dirlinks --safe-links ${nixEnv}/ $out/ || true
  ''
