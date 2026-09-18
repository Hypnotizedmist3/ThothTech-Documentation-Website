#!/usr/bin/env bash
# Rolls production back to the previous known-good ("stable-prev") image.
# Called automatically from the Jenkinsfile's post{failure{}} block, and
# runnable by hand for the demo video (great thing to show live).
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-thothtech-docs}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if docker image inspect "${IMAGE_NAME}:stable-prev" >/dev/null 2>&1; then
    docker tag "${IMAGE_NAME}:stable-prev" "${IMAGE_NAME}:stable"
    "${SCRIPT_DIR}/deploy.sh" production stable
    echo "Rolled production back to the previous stable image."
else
    echo "No previous stable image found — nothing to roll back to." >&2
    exit 1
fi
