# To compute sha256 for a new image or update an existing one:
#   bash nix/fetch-hashes.sh
#
# The sha256 is the recursive SRI hash of the OCI directory layout
# produced by `skopeo copy docker://... dir:...`.
{
  nix = {
    "2.32.8" = {
      imageName = "nixos/nix";
      imageDigest = "sha256:080e6df285c98b2ea34080bf3762308288e73d7f4012e3bcf96bb98911a24311";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };
  ubuntu = {
    "24_04" = {
      imageName = "ubuntu";
      imageDigest = "sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b";
      sha256 = "sha256-WY5c90AYDJPdB3aTCv+2nw29+4TmYv6HYQtaqOcqCfw=";
    };
  };
}
