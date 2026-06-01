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
      allPackages = import ./packages.nix { inherit pkgs lib type; };

      rootEnv = pkgs.buildEnv {
        name = "root";
        paths = allPackages;
        pathsToLink = [ "/" ];
        ignoreCollisions = true;
      };
    in

    # Build and compress an FHS environment that follows UsrMerge:
    # https://www.freedesktop.org/wiki/Software/systemd/TheCaseForTheUsrMerge
    pkgs.runCommand name
      {
        nativeBuildInputs = with pkgs; [
          libarchive
          fakeroot
        ];
      }
      ''
        set -e
        ROOTFS_DIR=$(mktemp -d)

        # standard Linux directories
        mkdir -p "$ROOTFS_DIR"/{etc,tmp,var,dev,proc,sys,run,root,home,media,mnt,opt,srv,usr}

        # copy packages on top (under fakeroot for correct ownership)
        # NOTE: symlinks are dereferenced and broken ones are ignored
        fakeroot cp -rL "${rootEnv}/." "$ROOTFS_DIR/" || true

        # Convert to usrmerge layout: move content from /{bin,lib,lib64,sbin}
        # to /usr/{bin,lib,lib64,sbin} and replace with symlinks
        for dir in bin lib lib64 sbin; do
          if [ -d "$ROOTFS_DIR/$dir" ] && [ ! -L "$ROOTFS_DIR/$dir" ]; then
            mkdir -p "$ROOTFS_DIR/usr"
            mv "$ROOTFS_DIR/$dir" "$ROOTFS_DIR/usr/$dir"
            ln -sf "usr/$dir" "$ROOTFS_DIR/$dir"
          fi
        done

        # Create tar.gz with exclusions (under fakeroot for root ownership in archive)
        mkdir -p "$out"
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
    type = "full";
  };
  ubuntu-rootfs = mkTarball {
    name = "ubuntu-rootfs";
    type = "full";
  };
}
