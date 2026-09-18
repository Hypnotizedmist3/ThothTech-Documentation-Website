#!/usr/bin/env bash
# Release stage: promotes a version that has already passed staging to
# production. Retags the current "stable" image as "stable-prev" first so
# scripts/rollback.sh can instantly revert if production fails its own
# health check.
#
# Usage: scripts/release.sh <version-tag>
set -euo pipefail

VERSION="${1:?usage: release.sh <version>}"
IMAGE_NAME="${IMAGE_NAME:-thothtech-docs}"

if docker image inspect "${IMAGE_NAME}:stable" >/dev/null 2>&1; then
    docker tag "${IMAGE_NAME}:stable" "${IMAGE_NAME}:stable-prev"
    echo "Kept previous production image as ${IMAGE_NAME}:stable-prev for rollback"
fi

docker tag "${IMAGE_NAME}:${VERSION}" "${IMAGE_NAME}:stable"
echo "Promoting ${IMAGE_NAME}:${VERSION} -> ${IMAGE_NAME}:stable (production)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/deploy.sh" production stable
