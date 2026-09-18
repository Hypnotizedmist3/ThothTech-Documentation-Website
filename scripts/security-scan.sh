#!/usr/bin/env bash
# Security stage: dependency scan (npm audit) + filesystem and image scan (Trivy).
# Non-blocking by design (exit 0) so a single new CVE in a transitive dependency
# doesn't take the whole site offline — findings are written to reports/ and
# MUST be reviewed and written up in the assignment report (issue, severity,
# whether/how addressed), per the assignment brief's Security stage requirement.
set -uo pipefail

IMAGE_NAME="${IMAGE_NAME:-thothtech-docs}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
mkdir -p reports

echo "=================================================="
echo " npm audit (dependency vulnerabilities)"
echo "=================================================="
npm audit --json > reports/npm-audit.json 2>/dev/null || true
npm audit --audit-level=high || echo "(npm audit found issues at/above 'high' — see reports/npm-audit.json)"

echo "=================================================="
echo " Trivy filesystem scan (source + lockfile)"
echo "=================================================="
if command -v trivy >/dev/null 2>&1; then
    trivy fs --format json --output reports/trivy-fs.json --severity HIGH,CRITICAL . || true
    trivy fs --severity HIGH,CRITICAL --exit-code 0 .
else
    echo "Trivy not installed — run scripts/install-trivy.sh first" | tee reports/trivy-fs-SKIPPED.txt
fi

echo "=================================================="
echo " Trivy image scan (${IMAGE_NAME}:${IMAGE_TAG})"
echo "=================================================="
if command -v trivy >/dev/null 2>&1 && docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1; then
    trivy image --format json --output reports/trivy-image.json --severity HIGH,CRITICAL "${IMAGE_NAME}:${IMAGE_TAG}" || true
    trivy image --severity HIGH,CRITICAL --exit-code 0 "${IMAGE_NAME}:${IMAGE_TAG}"
else
    echo "Skipping image scan — image not found or Trivy missing" | tee reports/trivy-image-SKIPPED.txt
fi

echo "Security stage complete. Review reports/ before writing up findings in your report."
exit 0
