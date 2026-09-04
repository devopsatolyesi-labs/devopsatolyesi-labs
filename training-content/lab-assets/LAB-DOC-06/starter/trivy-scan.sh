#!/usr/bin/env bash
set -euo pipefail

# TODO: Docker üzerinden aquasec/trivy imajını çalıştırarak 'alpine:3.21' imajını tarayın:
# 1. Yalnızca CRITICAL seviyesindeki açıkları filtreleyin (--severity CRITICAL)
# 2. Henüz düzeltmesi (fix) olmayan açıkları hariç tutun (--ignore-unfixed)
# 3. Kritik açık tespit edildiğinde exit code 1 üretin (--exit-code 1)
# 4. Host Docker socket'ini bağlayın (-v /var/run/docker.sock:/var/run/docker.sock)

# docker run --rm -v /var/run/docker.sock:/var/run/docker.sock #   aquasec/trivy:0.74.0 image #   --severity CRITICAL #   --ignore-unfixed #   --exit-code 1 #   alpine:3.21
