#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE_TAG:?IMAGE_TAG is required}"
: "${CHART_VERSION:?CHART_VERSION is required}"

GCP_PROJECT_ID=${GCP_PROJECT_ID:-devops-atolyesi-training}
GCP_ZONE=${GCP_ZONE:-europe-west1-b}
BUILD_INSTANCE=${BUILD_INSTANCE:-training-platform-01}
DEPLOY_USER=${DEPLOY_USER:-devopsadmin}
REGISTRY=${REGISTRY:-harbor.devopsatolyesi.com}
IMAGE=${IMAGE:-${REGISTRY}/library/labs-portal}

case "$IMAGE_TAG" in
  *[!a-zA-Z0-9._-]*|'') echo "Invalid IMAGE_TAG" >&2; exit 2 ;;
esac
case "$CHART_VERSION" in
  *[!0-9A-Za-z.+-]*|'') echo "Invalid CHART_VERSION" >&2; exit 2 ;;
esac

for command_name in git gcloud helm jq; do
  command -v "$command_name" >/dev/null || {
    echo "$command_name is required" >&2
    exit 2
  }
done

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
publish_tmp=$(mktemp -d /tmp/devopsatolyesi-labs-publish.XXXXXX)
remote_dir="/tmp/devopsatolyesi-labs-publish-${IMAGE_TAG}"

cleanup() {
  gcloud compute ssh "${DEPLOY_USER}@${BUILD_INSTANCE}" \
    --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" \
    --tunnel-through-iap --quiet \
    --command "sudo rm -rf '$remote_dir'" >/dev/null 2>&1 || true
  rm -rf "$publish_tmp"
}
trap cleanup EXIT

git -C "$repo_root" archive --format=tar.gz --output "$publish_tmp/source.tgz" HEAD

gcloud compute ssh "${DEPLOY_USER}@${BUILD_INSTANCE}" \
  --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" \
  --tunnel-through-iap --quiet \
  --command "sudo rm -rf '$remote_dir'; install -d -m 700 '$remote_dir'"
gcloud compute scp "$publish_tmp/source.tgz" \
  "${DEPLOY_USER}@${BUILD_INSTANCE}:${remote_dir}/source.tgz" \
  --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" \
  --tunnel-through-iap --quiet

gcloud compute ssh "${DEPLOY_USER}@${BUILD_INSTANCE}" \
  --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" \
  --tunnel-through-iap --quiet \
  --command "set -eu; cd '$remote_dir'; tar -xzf source.tgz; robot_name=\$(sudo jq -er .name /opt/devops-atolyesi/harbor/state/robot-credentials.json); robot_secret=\$(sudo jq -er .secret /opt/devops-atolyesi/harbor/state/robot-credentials.json); printf '%s' \"\$robot_secret\" | docker login '$REGISTRY' --username \"\$robot_name\" --password-stdin >/dev/null; docker build --platform linux/amd64 -t '$IMAGE:$IMAGE_TAG' -f portal/Dockerfile .; docker push '$IMAGE:$IMAGE_TAG'; docker logout '$REGISTRY' >/dev/null"

gcloud compute ssh "${DEPLOY_USER}@${BUILD_INSTANCE}" \
  --project "$GCP_PROJECT_ID" --zone "$GCP_ZONE" \
  --tunnel-through-iap --quiet \
  --command "sudo sh -c 'test \"\$(stat -c %a:%U:%G /opt/devops-atolyesi/harbor/state/robot-credentials.json)\" = 600:root:root && base64 --wrap=0 /opt/devops-atolyesi/harbor/state/robot-credentials.json'" \
  > "$publish_tmp/robot-credentials.json.b64"

if base64 -D -i /dev/null -o /dev/null >/dev/null 2>&1; then
  base64 -D -i "$publish_tmp/robot-credentials.json.b64" -o "$publish_tmp/robot-credentials.json"
else
  base64 --decode "$publish_tmp/robot-credentials.json.b64" > "$publish_tmp/robot-credentials.json"
fi
chmod 600 "$publish_tmp/robot-credentials.json"
robot_name=$(jq -er .name "$publish_tmp/robot-credentials.json")
robot_secret=$(jq -er .secret "$publish_tmp/robot-credentials.json")

cp -R "$repo_root/charts/labs-portal" "$publish_tmp/labs-portal"
sed -i.bak -E "s/^  tag: .*/  tag: ${IMAGE_TAG}/" "$publish_tmp/labs-portal/values.yaml"
rm -f "$publish_tmp/labs-portal/values.yaml.bak"
helm package "$publish_tmp/labs-portal" \
  --version "$CHART_VERSION" --app-version "$IMAGE_TAG" \
  --destination "$publish_tmp"
HELM_REGISTRY_CONFIG="$publish_tmp/helm-registry.json" \
  helm registry login "$REGISTRY" --username "$robot_name" --password-stdin \
  <<<"$robot_secret"
HELM_REGISTRY_CONFIG="$publish_tmp/helm-registry.json" \
  helm push "$publish_tmp/devops-atolyesi-labs-portal-${CHART_VERSION}.tgz" \
  "oci://${REGISTRY}/library"
HELM_REGISTRY_CONFIG="$publish_tmp/helm-registry.json" \
  helm registry logout "$REGISTRY" >/dev/null

echo "Published ${IMAGE}:${IMAGE_TAG} and Labs chart ${CHART_VERSION}"
