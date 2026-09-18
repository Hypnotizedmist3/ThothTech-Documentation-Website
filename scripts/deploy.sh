#!/usr/bin/env bash
# Deploys a built image to either "staging" (port 8081) or "production" (port 8080)
# as a Docker container, waits for its /healthz to go green, and fails the build
# if it doesn't come up — this is the automated gate between Deploy and Release.
#
# Usage: scripts/deploy.sh <staging|production> <version-tag>
set -euo pipefail

ENV="${1:?usage: deploy.sh <staging|production> <version>}"
VERSION="${2:?usage: deploy.sh <staging|production> <version>}"
IMAGE_NAME="${IMAGE_NAME:-thothtech-docs}"
NETWORK="thothtech-net"

case "$ENV" in
    staging) PORT=8081 ;;
    production) PORT=8080 ;;
    *) echo "Unknown environment '$ENV' (expected staging|production)" >&2; exit 1 ;;
esac

CONTAINER="thothtech-docs-${ENV}"

docker network create "$NETWORK" >/dev/null 2>&1 || true

echo "Deploying ${IMAGE_NAME}:${VERSION} to ${ENV} on port ${PORT}..."
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d \
    --name "$CONTAINER" \
    --network "$NETWORK" \
    --network-alias "$CONTAINER" \
    -p "${PORT}:80" \
    --label "thothtech.env=${ENV}" \
    --label "thothtech.version=${VERSION}" \
    "${IMAGE_NAME}:${VERSION}"

echo "Waiting for ${ENV} health check..."
for i in $(seq 1 20); do
    if curl -sf "http://localhost:${PORT}/healthz" > /dev/null; then
        echo "${ENV} is healthy after ${i} attempt(s): http://localhost:${PORT}"
        exit 0
    fi
    sleep 2
done

echo "Health check FAILED for ${ENV} — rolling back the deploy" >&2
docker logs "$CONTAINER" --tail 50 || true
docker rm -f "$CONTAINER" || true
exit 1
