#!/usr/bin/env bash
# Installs the ATS120 environment. The same script runs in every playground
# and lab of this repository; change it everywhere at once.
#
# It prepares the environment only:
#   1. puts Helm (pinned) on the PATH,
#   2. makes registry.localtest.me resolve to the in-cluster registry,
#   3. applies the registry, namespaces, service accounts and RBAC,
#   4. installs the private Sigstore stack (chart scaffold 0.6.117) with Fulcio
#      trusting this cluster's service account token issuer,
#   5. builds trusted-root.json and signing-config.json and stores them in the
#      ConfigMap sigstore-trust in every namespace that signs,
#   6. starts the workstation pod and copies the example image.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

HELM_VERSION="3.22.1"
SCAFFOLD_CHART_VERSION="0.6.117"
REGISTRY_HOST="registry.localtest.me"
SIGN_NAMESPACES="${SIGN_NAMESPACES:-workstation ci}"
LOG_PREFIX="${LOG_PREFIX:-[playground]}"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

have_helm=""
command -v helm >/dev/null 2>&1 && have_helm=$(helm version --template '{{.Version}}' 2>/dev/null | sed 's/^v//')
if [ "$have_helm" != "$HELM_VERSION" ]; then
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
  echo "$LOG_PREFIX Downloading Helm ${HELM_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz" | tar -xz -C "$WORK"
  install -m 0755 "$WORK/${OS}-${ARCH}/helm" "$BIN_DIR/helm"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR=""
for candidate in "$SCRIPT_DIR/../manifests" "./manifests" "$SCRIPT_DIR/manifests"; do
  [ -d "$candidate" ] && { MANIFEST_DIR="$candidate"; break; }
done

# One name for the registry everywhere in the cluster. The answer is rewritten
# back to the asked name: Go programs (cosign included) ignore DNS answers whose
# name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$REGISTRY_HOST"; then
  echo "$LOG_PREFIX Adding the CoreDNS rewrite for ${REGISTRY_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex registry\\.localtest\\.me registry.registry.svc.cluster.local"
        print "        answer name registry\\.registry\\.svc\\.cluster\\.local registry.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

echo "$LOG_PREFIX Applying the registry, namespaces and service accounts..."
kubectl apply -f "$MANIFEST_DIR/lab-start.yaml"
kubectl -n registry rollout status deployment/registry --timeout=300s

# The issuer Fulcio must trust is the one this cluster writes into its
# service account tokens. Read it from the API server instead of guessing.
OIDC_ISSUER="$(kubectl get --raw /.well-known/openid-configuration | tr -d ' \n' | sed -n 's/.*"issuer":"\([^"]*\)".*/\1/p')"
[ -n "$OIDC_ISSUER" ] || { echo "$LOG_PREFIX ERROR: could not read the service account issuer." >&2; exit 1; }
echo "$LOG_PREFIX Service account issuer: $OIDC_ISSUER"

# Fulcio v1.9.0 trusts the cluster CA for a kubernetes issuer only when the
# configuration also lists https://kubernetes.default.svc.
{
  echo "fulcio:"
  echo "  config:"
  echo "    contents:"
  echo "      OIDCIssuers:"
  echo "        \"https://kubernetes.default.svc\":"
  echo "          IssuerURL: \"https://kubernetes.default.svc\""
  echo "          ClientID: sigstore"
  echo "          Type: kubernetes"
  if [ "$OIDC_ISSUER" != "https://kubernetes.default.svc" ]; then
    echo "        \"$OIDC_ISSUER\":"
    echo "          IssuerURL: \"$OIDC_ISSUER\""
    echo "          ClientID: sigstore"
    echo "          Type: kubernetes"
  fi
} > "$WORK/fulcio-issuers.yaml"

echo "$LOG_PREFIX Installing the private Sigstore stack (chart scaffold ${SCAFFOLD_CHART_VERSION}); this takes several minutes..."
helm repo add sigstore https://sigstore.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update sigstore >/dev/null
helm upgrade --install sigstore sigstore/scaffold --version "$SCAFFOLD_CHART_VERSION" \
  --namespace sigstore-system --create-namespace \
  --values "$MANIFEST_DIR/sigstore-values.yaml" \
  --values "$WORK/fulcio-issuers.yaml" \
  --timeout 20m
for target in trillian-system/trillian-logserver fulcio-system/fulcio-server ctlog-system/ctlog rekor-system/rekor-server; do
  ns="${target%%/*}"; deploy="${target#*/}"
  for _ in $(seq 1 120); do
    kubectl -n "$ns" get deployment "$deploy" >/dev/null 2>&1 && break
    sleep 5
  done
  kubectl -n "$ns" rollout status "deployment/$deploy" --timeout=900s
done

echo "$LOG_PREFIX Starting the workstation pod..."
kubectl apply -f "$MANIFEST_DIR/workstation.yaml"
kubectl -n workstation rollout status deployment/workstation --timeout=600s
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
for _ in $(seq 1 60); do ws sh -c 'command -v jq >/dev/null' 2>/dev/null && break; sleep 5; done

# Trust material of the private stack. The public-good instance ships the same
# two files through TUF; this stack has no TUF server, so they are built here.
if ! kubectl -n workstation get configmap sigstore-trust >/dev/null 2>&1; then
  echo "$LOG_PREFIX Building trusted-root.json and signing-config.json..."
  for _ in $(seq 1 60); do
    kubectl -n fulcio-system get secret fulcio-server-secret >/dev/null 2>&1 \
      && kubectl -n ctlog-system get secret ctlog-public-key >/dev/null 2>&1 && break
    sleep 5
  done
  kubectl -n fulcio-system get secret fulcio-server-secret -o jsonpath='{.data.cert}' | base64 -d > "$WORK/fulcio.pem"
  kubectl -n ctlog-system get secret ctlog-public-key -o jsonpath='{.data.public}' | base64 -d > "$WORK/ctfe.pub"
  for _ in $(seq 1 60); do
    ws curl -fsS http://rekor-server.rekor-system.svc/api/v1/log/publicKey > "$WORK/rekor.pub" 2>/dev/null && [ -s "$WORK/rekor.pub" ] && break
    sleep 5
  done
  ws mkdir -p /tmp/trust
  for f in fulcio.pem ctfe.pub rekor.pub; do
    ws sh -c "cat > /tmp/trust/$f" < "$WORK/$f"
  done
  ws cosign trusted-root create \
    --fulcio="url=http://fulcio-server.fulcio-system.svc,certificate-chain=/tmp/trust/fulcio.pem" \
    --rekor="url=http://rekor-server.rekor-system.svc,public-key=/tmp/trust/rekor.pub,start-time=2026-01-01T00:00:00Z" \
    --ctfe="url=http://ctlog.ctlog-system.svc/sigstorescaffolding,public-key=/tmp/trust/ctfe.pub,start-time=2026-01-01T00:00:00Z" \
    --out /tmp/trust/trusted-root.json
  ws cosign signing-config create \
    --fulcio="url=http://fulcio-server.fulcio-system.svc,api-version=1,start-time=2026-01-01T00:00:00Z,operator=astrona.lab" \
    --rekor="url=http://rekor-server.rekor-system.svc,api-version=1,start-time=2026-01-01T00:00:00Z,operator=astrona.lab" \
    --rekor-config=ANY \
    --out /tmp/trust/signing-config.json
  ws cat /tmp/trust/trusted-root.json > "$WORK/trusted-root.json"
  ws cat /tmp/trust/signing-config.json > "$WORK/signing-config.json"
  printf '%s' "$OIDC_ISSUER" > "$WORK/oidc-issuer"
  for ns in $SIGN_NAMESPACES; do
    kubectl get namespace "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns"
    kubectl -n "$ns" create configmap sigstore-trust \
      --from-file=trusted-root.json="$WORK/trusted-root.json" \
      --from-file=signing-config.json="$WORK/signing-config.json" \
      --from-file=oidc-issuer="$WORK/oidc-issuer" \
      --dry-run=client -o yaml | kubectl apply -f -
  done
  # Restart so the pod sees the new ConfigMap at once.
  kubectl -n workstation rollout restart deployment/workstation
  kubectl -n workstation rollout status deployment/workstation --timeout=600s
  for _ in $(seq 1 60); do ws test -s /etc/sigstore/trusted-root.json 2>/dev/null && ws sh -c 'command -v jq >/dev/null' 2>/dev/null && break; sleep 5; done
fi

echo "$LOG_PREFIX Copying the example image into the registry..."
ws regctl image copy --platform linux/amd64 \
  ghcr.io/stefanprodan/podinfo:6.15.0 registry.localtest.me:5001/inventory/podinfo:6.15.0

echo "$LOG_PREFIX Sigstore environment ready."
