#!/usr/bin/env bash
set -euo pipefail

: "${HARBOR_ROBOT_USERNAME:?HARBOR_ROBOT_USERNAME is required}"
: "${HARBOR_ROBOT_PASSWORD:?HARBOR_ROBOT_PASSWORD is required}"
: "${KEYCLOAK_DB_PASSWORD:?KEYCLOAK_DB_PASSWORD is required}"
: "${PLATFORM_ADMIN_PASSWORD:?PLATFORM_ADMIN_PASSWORD is required}"
: "${LABS_ADMIN_PASSWORD:?LABS_ADMIN_PASSWORD is required}"
: "${LABS_DEVOPS_PASSWORD:?LABS_DEVOPS_PASSWORD is required}"
: "${LABS_KUBERNETES_PASSWORD:?LABS_KUBERNETES_PASSWORD is required}"

registry=harbor.devopsatolyesi.com

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace identity-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace labs-system --dry-run=client -o yaml | kubectl apply -f -

kubectl -n argocd create secret generic harbor-oci-charts \
  --from-literal=type=helm \
  --from-literal=name=harbor-oci-charts \
  --from-literal=url="$registry/library" \
  --from-literal=enableOCI=true \
  --from-literal=username="$HARBOR_ROBOT_USERNAME" \
  --from-literal=password="$HARBOR_ROBOT_PASSWORD" \
  --dry-run=client -o yaml |
  kubectl label --local -f - argocd.argoproj.io/secret-type=repository -o yaml |
  kubectl apply -f -

kubectl -n labs-system create secret docker-registry harbor-registry \
  --docker-server="$registry" \
  --docker-username="$HARBOR_ROBOT_USERNAME" \
  --docker-password="$HARBOR_ROBOT_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n identity-system create secret generic keycloak-secrets \
  --from-literal=postgres-password="$KEYCLOAK_DB_PASSWORD" \
  --from-literal=admin-password="$PLATFORM_ADMIN_PASSWORD" \
  --from-literal=realm-admin-password="$LABS_ADMIN_PASSWORD" \
  --from-literal=devops-password="$LABS_DEVOPS_PASSWORD" \
  --from-literal=kubernetes-password="$LABS_KUBERNETES_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f gitops/applications.yaml
kubectl -n argocd get applications.argoproj.io labs-keycloak labs-portal
