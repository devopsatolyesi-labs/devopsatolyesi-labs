#!/usr/bin/env bash
set -euo pipefail
kubectl delete namespace lab-k8s-15 --ignore-not-found=true
helm uninstall lab-nfs -n lab-k8s-15-system --ignore-not-found
kubectl delete namespace lab-k8s-15-system --ignore-not-found=true
sudo rm -f /etc/exports.d/lab-k8s-15.exports
sudo exportfs -ra
sudo rm -rf /srv/nfs/lab-k8s-15
