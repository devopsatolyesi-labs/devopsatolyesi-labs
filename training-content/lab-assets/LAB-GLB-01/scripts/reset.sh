#!/usr/bin/env bash
set -euo pipefail
echo "Resetting workspace for LAB-GLB-01..."
bash "/Users/hakan/devops-workspace/devopsatolyesi-training-platform-bootstrap/training-content/lab-assets/LAB-GLB-01/scripts/cleanup.sh"
cp -r "/Users/hakan/devops-workspace/devopsatolyesi-training-platform-bootstrap/training-content/lab-assets/LAB-GLB-01/starter"/* . 2>/dev/null || true
echo "Workspace reset to starter state for LAB-GLB-01."
