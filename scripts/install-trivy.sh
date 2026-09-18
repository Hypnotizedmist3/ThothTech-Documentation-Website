#!/usr/bin/env bash
# Installs the Trivy CLI (security scanner) if it isn't already on PATH.
# Safe to run every pipeline build — it's a no-op once installed.
set -euo pipefail

if command -v trivy >/dev/null 2>&1; then
    echo "Trivy already installed: $(trivy --version | head -1)"
    exit 0
fi

OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
        echo "Installing Trivy via Homebrew..."
        brew install trivy
        exit 0
    else
        echo "Homebrew not found. Install it from https://brew.sh, or install Trivy manually:"
        echo "  https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
        exit 1
    fi
else
    echo "Installing Trivy via install script..."
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
        sh -s -- -b /usr/local/bin
fi

trivy --version
