#!/usr/bin/env bash
set -euo pipefail
test -f sonar-project.properties
echo "[PASS] SonarQube configuration file exists."
