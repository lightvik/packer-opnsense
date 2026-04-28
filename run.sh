#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/lightvik/packer-opnsense:latest"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

docker run \
  --rm \
  --device /dev/kvm \
  --network=host \
  --volume "$PROJECT_DIR:/workspace" \
  "$IMAGE" \
  "$@"
