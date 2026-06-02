{
  images,
  pkgs,
  lib,
  n2c,
}:

let
  mkTarball =
    {
      name,
      type,
    }:

    pkgs.runCommand name
      {
        nativeBuildInputs = with pkgs; [
          gnutar
          gzip
          umoci
        ];
        LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      }
      ''
        export HOME="$PWD"
        export TMPDIR="$PWD/tmp"
        mkdir -p "$TMPDIR" oci-layout unpacked

        # copy image to OCI layout directory (matches oci2 approach)
        ${images.default.copyTo}/bin/copy-to oci:./oci-layout:latest

        # unpack using umoci (correctly handles whiteouts, etc.)
        umoci unpack --rootless --image ./oci-layout:latest ./unpacked

        # create compressed tarball
        tar -c -C ./unpacked/rootfs . | gzip > "$out/${name}.tar.gz"
      '';
in

{
  default-rootfs = mkTarball {
    name = "felix86-rootfs";
    type = "full";
  };
}
