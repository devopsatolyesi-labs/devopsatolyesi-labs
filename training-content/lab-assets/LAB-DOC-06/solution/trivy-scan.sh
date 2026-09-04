#!/usr/bin/env bash
set -euo pipefail
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock   aquasec/trivy:0.74.0 image --severity CRITICAL --exit-code 1 --ignore-unfixed alpine:3.21
