#!/usr/bin/env bash
docker rm -f backend-service frontend-service 2>/dev/null || true
docker network rm custom-app-net 2>/dev/null || true
docker rmi lab-doc-09-frontend:v1 2>/dev/null || true
echo "Cleanup completed for LAB-DOC-09."
