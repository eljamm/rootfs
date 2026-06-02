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

    pkgs.runCommand name
      {
        nativeBuildInputs = with pkgs; [
          gnutar
          gzip
          jq
        ];
      }
      ''
        mkdir -p root image

        # extract OCI image tarball
        tar xf "${images.default}" -C image

        # apply layers in order (from manifest.json)
        jq -r '.[0].Layers[]' image/manifest.json | while read layer; do
          tar xf "image/$layer" -C root
        done

        # create flat rootfs tarball
        tar czf "$out/${name}.tar.gz" -C root .
      '';
in

{
  default-rootfs = mkTarball {
    name = "felix86-rootfs";
    type = "full";
  };
}
