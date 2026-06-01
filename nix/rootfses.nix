{
  pkgs,
  lib,
}:

let
  baseImages = import ./base-images.nix;

  mkPulledImage =
    {
      imageName,
      imageDigest,
      sha256,
    }:
    pkgs.runCommand "pulled-${builtins.replaceStrings [ "/" ":" ] [ "-" "-" ] imageName}"
      {
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = sha256;
        nativeBuildInputs = with pkgs; [
          skopeo
          cacert
        ];
        impureEnvVars = lib.fetchers.proxyImpureEnvVars;
      }
      ''
        skopeo copy "docker://${imageName}@${imageDigest}" "dir:$out" \
          --insecure-policy --override-os linux --override-arch amd64
      '';

  mkTarball =
    {
      name,
      baseImageSpec,
      type,
    }:

    let
      allPackages = import ./packages.nix {
        inherit pkgs lib type;
      };
      rootEnv = pkgs.buildEnv {
        name = "root";
        paths = allPackages;
        pathsToLink = [ "/" ];
        ignoreCollisions = true;
      };
      pulled = mkPulledImage baseImageSpec;
    in
    pkgs.runCommand name
      {
        nativeBuildInputs = with pkgs; [
          libarchive
          jq
          fakeroot
        ];
      }
      ''
        set -e
        ROOTFS_DIR=$(mktemp -d)

        # Extract base image layers
        manifest="${pulled}/manifest.json"
        if [ -f "$manifest" ]; then
          cat "$manifest" | jq -r '.layers[].digest' | while read digest; do
            hash="''${digest#sha256:}"
            layer_file="${pulled}/$hash"
            if [ -f "$layer_file" ]; then
              echo "Extracting layer: $hash"
              bsdtar -xf "$layer_file" -C "$ROOTFS_DIR" 2>/dev/null || true
            fi
          done
        fi

        # Layer our packages on top (under fakeroot for correct ownership)
        if [ -d "${rootEnv}" ]; then
          ${pkgs.fakeroot}/bin/fakeroot cp -rL "${rootEnv}/." "$ROOTFS_DIR/"
        fi

        # Create tar.gz with exclusions (under fakeroot for root ownership in archive)
        ${pkgs.fakeroot}/bin/fakeroot bsdtar -czf "$out/${name}.tar.gz" \
          --exclude=media --exclude=mnt --exclude=root --exclude=srv \
          --exclude=boot --exclude=home --exclude=run --exclude=proc \
          --exclude=sys --exclude=dev --exclude=tmp --exclude=.dockerenv \
          -C "$ROOTFS_DIR" .

        rm -rf "$ROOTFS_DIR"
        echo "Done: $out/${name}.tar.gz"
      '';
in

{
  nix-rootfs = mkTarball {
    name = "nix-rootfs";
    baseImageSpec = baseImages.nix."2.32.8";
    type = "full";
  };
  ubuntu-rootfs = mkTarball {
    name = "ubuntu-rootfs";
    baseImageSpec = baseImages.ubuntu."24_04";
    type = "full";
  };
}
