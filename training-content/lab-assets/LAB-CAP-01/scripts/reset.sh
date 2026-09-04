#!/usr/bin/env bash
set -euo pipefail
echo "Resetting workspace for LAB-CAP-01..."
bash "/Users/hakan/devops-workspace/devopsatolyesi-training-platform-bootstrap/training-content/lab-assets/LAB-CAP-01/scripts/cleanup.sh"
cp -r "/Users/hakan/devops-workspace/devopsatolyesi-training-platform-bootstrap/training-content/lab-assets/LAB-CAP-01/starter"/* . 2>/dev/null || true
echo "Workspace reset to starter state for LAB-CAP-01."
