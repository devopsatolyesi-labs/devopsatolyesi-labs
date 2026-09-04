#!/usr/bin/env bash
docker compose -p lab-doc-02 down -v 2>/dev/null || true
echo "Cleanup completed for LAB-DOC-02."
