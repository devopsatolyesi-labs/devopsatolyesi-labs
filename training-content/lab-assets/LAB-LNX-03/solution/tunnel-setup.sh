#!/usr/bin/env bash
set -euo pipefail

# SSH Local Port Forwarding (Arka planda tünel açma)
# Yerel 33306 -> Uzak MySQL 3306
echo "==> SSH Tüneli Başlatılıyor (Local Port Forwarding 33306:127.0.0.1:3306)..."
# ssh -f -N -L 33306:127.0.0.1:3306 user@bastion-host
echo "ssh -N -L 33306:127.0.0.1:3306 bastion-user@bastion.devopsatolyesi.local" > ~/ssh-tunnel-command.txt
