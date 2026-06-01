#!/usr/bin/env bash
# Computes sha256 SRI hashes for base images.
# These go into the `sha256` field in base-images.nix.
set -euo pipefail

HASHES="base-images.nix"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

fetch_hash() {
    local image_name=$1
    local image_digest=$2

    echo "==> Pulling ${image_name}@${image_digest} ..."
    skopeo copy "docker://${image_name}@${image_digest}" "dir:${TMPDIR}/${image_name}" \
        --insecure-policy --override-os linux --override-arch amd64

    echo "==> Computing hash ..."
    nix hash path "${TMPDIR}/${image_name}" --type sha256 --sri
}

echo "=== Fetching base image hashes ==="
echo ""

echo "nix 2.32.8:"
HASH=$(fetch_hash "nixos/nix" "sha256:080e6df285c98b2ea34080bf3762308288e73d7f4012e3bcf96bb98911a24311")
echo "  sha256 = \"${HASH}\";"
echo ""

echo "ubuntu 24.04:"
HASH=$(fetch_hash "ubuntu" "sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b")
echo "  sha256 = \"${HASH}\";"
echo ""

echo "=== Done ==="
echo "Copy the sha256 values above into ${HASHES}"
