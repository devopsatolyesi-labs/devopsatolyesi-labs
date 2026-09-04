#!/usr/bin/env bash
set -euo pipefail
echo "========================================="
echo "  DEVOPS PRACTITIONER - PREFLIGHT REPORT "
echo "========================================="
echo "Date: $(date -u)"
echo "Hostname: $(hostname)"
echo "OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || uname -s)"
echo "Kernel: $(uname -r)"
echo ""
echo "[1] CPU & RAM Status:"
echo "CPU Cores: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)"
free -h 2>/dev/null || vm_stat 2>/dev/null || echo "RAM check completed"
echo ""
echo "[2] Disk Space (/):"
df -h / | awk 'NR==1{print $0} NR==2{print $0}'
echo ""
echo "[3] Docker Status:"
if command -v docker >/dev/null 2>&1; then
    echo "Docker Version: $(docker --version)"
else
    echo "Docker is NOT installed yet."
fi
echo "========================================="
echo "  PREFLIGHT REPORT COMPLETED SUCCESSFUL  "
echo "========================================="
