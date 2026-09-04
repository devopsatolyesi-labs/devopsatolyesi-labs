#!/usr/bin/env bash
docker rm -f lab-doc-01-test 2>/dev/null || true
docker rmi devops-first-container:v1 2>/dev/null || true
echo "Cleanup completed for LAB-DOC-01."
