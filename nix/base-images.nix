# nix run nixpkgs#nix-prefetch-docker -- --image-name <name> --image-tag <tag>
{
  fedora = {
    "43" = {
      imageName = "fedora";
      imageDigest = "sha256:781b7642e8bf256e9cf75d2aa58d86f5cc695fd2df113517614e181a5eee9138";
      hash = "sha256-wYSv2eFGW5HHeiV6jmfZbMu6rUIXPeEascz+ycR8uVo=";
      finalImageName = "fedora";
      finalImageTag = "43";
    };
  };
  ubuntu = {
    "24_04" = {
      imageName = "ubuntu";
      imageDigest = "sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b";
      hash = "sha256-4fNRgZzYvIKgzdJDOK5IH5fBkmzQQNMIDAEVoQj56Uk=";
      finalImageName = "ubuntu";
      finalImageTag = "24.04";
    };
  };
}
