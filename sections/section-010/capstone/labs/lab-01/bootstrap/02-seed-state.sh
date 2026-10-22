#!/usr/bin/env bash
# Creates the starting state for ats-120-capstone-010.
#
# Publishes a bundle signed with a thrown-away key, points the signing
# configuration at a Fulcio Service that does not exist, and gives the
# workstation token the wrong audience.
#
# What the task asks for is NOT created here - producing it is the task.
set -euo pipefail

ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
oidc_issuer() { kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.oidc-issuer}'; }
sa_identity() { echo "https://kubernetes.io/namespaces/$1/serviceaccounts/$2"; }
image_digest() { ws regctl image digest "$1"; }
# verify_image IDENTITY IMAGE: keyless verification against the private stack.
verify_image() {
  ws cosign verify --trusted-root /etc/sigstore/trusted-root.json --allow-http-registry \
    --certificate-identity "$1" --certificate-oidc-issuer "$(oidc_issuer)" "$2" >/dev/null 2>&1
}
# copy_trust NAMESPACE: copies the ConfigMap sigstore-trust into a namespace.
copy_trust() {
  kubectl get namespace "$1" >/dev/null 2>&1 || kubectl create namespace "$1"
  kubectl -n workstation get configmap sigstore-trust -o yaml \
    | sed -e '/^  namespace:/d' -e '/resourceVersion:/d' -e '/uid:/d' -e '/creationTimestamp:/d' \
    | kubectl -n "$1" apply -f -
}
# signer_job NAMESPACE SERVICEACCOUNT JOBNAME IMAGE [AUDIENCE]: prints a Job
# that signs IMAGE keylessly with the service account's projected token.
signer_job() {
  cat <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: $3
  namespace: $1
spec:
  backoffLimit: 0
  template:
    spec:
      serviceAccountName: $2
      restartPolicy: Never
      containers:
        - name: cosign
          image: ghcr.io/sigstore/cosign/cosign:v3.1.4
          args:
            - sign
            - --yes
            - --allow-http-registry
            - --identity-token=/var/run/sigstore/token
            - --signing-config=/etc/sigstore/signing-config.json
            - --trusted-root=/etc/sigstore/trusted-root.json
            - $4
          env:
            - name: HOME
              value: /tmp
          volumeMounts:
            - name: sigstore-trust
              mountPath: /etc/sigstore
              readOnly: true
            - name: sigstore-token
              mountPath: /var/run/sigstore
              readOnly: true
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: sigstore-trust
          configMap:
            name: sigstore-trust
        - name: sigstore-token
          projected:
            sources:
              - serviceAccountToken:
                  path: token
                  audience: ${5:-sigstore}
                  expirationSeconds: 600
        - name: tmp
          emptyDir: {}
YAML
}
# run_job NAMESPACE JOBNAME: waits for a Job to finish; returns non-zero if it failed.
run_job() {
  for _ in $(seq 1 120); do
    s="$(kubectl -n "$1" get job "$2" -o jsonpath='{.status.succeeded}' 2>/dev/null)"
    f="$(kubectl -n "$1" get job "$2" -o jsonpath='{.status.failed}' 2>/dev/null)"
    [ "${s:-0}" -ge 1 ] && return 0
    [ "${f:-0}" -ge 1 ] && return 1
    sleep 5
  done
  return 1
}
# sign_as NAMESPACE SERVICEACCOUNT JOBNAME IMAGE: signs and waits.
sign_as() {
  kubectl -n "$1" delete job "$3" --ignore-not-found >/dev/null
  signer_job "$1" "$2" "$3" "$4" | kubectl apply -f -
  run_job "$1" "$3"
}
# copy_image SOURCE DESTINATION: copies one linux/amd64 image into the registry.
copy_image() { ws regctl image copy --platform linux/amd64 "$1" "$2"; }
REG=registry.localtest.me:5001
# The release file: a small tarball in the workstation, also stored in the
# ConfigMap release-files so graders read the exact same bytes.
ws sh -c 'mkdir -p /work/release && cd /work/release && printf "inventory 1.0\n" > VERSION && tar czf inventory-1.0.tar.gz VERSION && rm VERSION'
TMP="$(mktemp -d)"
ws cat /work/release/inventory-1.0.tar.gz > "$TMP/inventory-1.0.tar.gz"
kubectl -n workstation create configmap release-files \
  --from-file=inventory-1.0.tar.gz="$TMP/inventory-1.0.tar.gz" --dry-run=client -o yaml | kubectl apply -f -
rm -rf "$TMP"

# 1. A bundle signed with a long-lived key pair (the key is thrown away).
ws sh -c 'cd /tmp && COSIGN_PASSWORD=lab-only-password cosign generate-key-pair --output-key-prefix legacy >/dev/null'
ws sh -c 'COSIGN_PASSWORD=lab-only-password cosign sign-blob --yes --key /tmp/legacy.key \
  --signing-config /etc/sigstore/signing-config.json --trusted-root /etc/sigstore/trusted-root.json \
  --bundle /work/release/inventory-1.0.tar.gz.sigstore.json /work/release/inventory-1.0.tar.gz'
ws rm -f /tmp/legacy.key /tmp/legacy.pub

TMP="$(mktemp -d)"
ws cat /work/release/inventory-1.0.tar.gz.sigstore.json > "$TMP/inventory-1.0.tar.gz.sigstore.json"
kubectl -n workstation create configmap release-bundle \
  --from-file=inventory-1.0.tar.gz.sigstore.json="$TMP/inventory-1.0.tar.gz.sigstore.json" \
  --dry-run=client -o yaml | kubectl apply -f -
rm -rf "$TMP"

# 2. The signing configuration names a Fulcio Service that does not exist.
TMP="$(mktemp -d)"
for key in trusted-root.json signing-config.json oidc-issuer; do
  kubectl -n workstation get configmap sigstore-trust -o jsonpath="{.data.${key//./\\.}}" > "$TMP/$key"
done
sed -i.bak 's#http://fulcio-server.fulcio-system.svc#http://fulcio.fulcio-system.svc#g' "$TMP/signing-config.json"
kubectl -n workstation create configmap sigstore-trust \
  --from-file=trusted-root.json="$TMP/trusted-root.json" \
  --from-file=signing-config.json="$TMP/signing-config.json" \
  --from-file=oidc-issuer="$TMP/oidc-issuer" --dry-run=client -o yaml | kubectl apply -f -
rm -rf "$TMP"
# 3. The workstation's token is issued for the wrong audience.
kubectl -n workstation patch deployment workstation --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/volumes/3/projected/sources/0/serviceAccountToken/audience","value":"sigstore-dev"}]'
kubectl -n workstation rollout status deployment/workstation --timeout=600s
for _ in $(seq 1 60); do ws sh -c 'command -v jq >/dev/null' 2>/dev/null && break; sleep 5; done
