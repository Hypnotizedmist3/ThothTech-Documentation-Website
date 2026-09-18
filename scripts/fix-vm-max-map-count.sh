#!/usr/bin/env bash
# Run this ONCE if SonarQube's container exits immediately with an error like
# "max virtual memory areas vm.max_map_count [65530] is too low". This bumps
# the setting inside Docker Desktop's Linux VM (harmless, resets on Docker
# Desktop restart — re-run this script if it happens again).
set -euo pipefail
docker run --rm --privileged --pid=host justincormack/nsenter1 \
    sysctl -w vm.max_map_count=262144
echo "Done. Re-run: docker compose -f docker-compose.sonarqube.yml up -d"
