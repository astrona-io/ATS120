#!/usr/bin/env bash
# Creates the starting state for ats-120-capstone-040.
#
# Creates the legacy pipeline: a key pair in the Secret cosign-key, the Job
# ci-sign-legacy that signs with it, and a key-based verification script.
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
kubectl -n ci create serviceaccount ci-builder --dry-run=client -o yaml | kubectl apply -f -
DIGEST="$(image_digest "$REG/inventory/podinfo:6.15.0")"
kubectl -n ci create configmap release-info --from-literal=image="$REG/inventory/podinfo@$DIGEST" \
  --dry-run=client -o yaml | kubectl apply -f -

# The legacy pipeline: a long-lived key pair in a Secret, used by a Job.
ws sh -c 'cd /tmp && rm -f cosign.key cosign.pub && COSIGN_PASSWORD=lab-only-password cosign generate-key-pair >/dev/null'
TMP="$(mktemp -d)"
ws cat /tmp/cosign.key > "$TMP/cosign.key"
ws cat /tmp/cosign.pub > "$TMP/cosign.pub"
ws rm -f /tmp/cosign.key /tmp/cosign.pub
kubectl -n ci create secret generic cosign-key --from-file=cosign.key="$TMP/cosign.key" \
  --from-literal=password=lab-only-password --dry-run=client -o yaml | kubectl apply -f -
IMAGE="$(kubectl -n ci get configmap release-info -o jsonpath='{.data.image}')"
kubectl apply -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: ci-sign-legacy
  namespace: ci
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: cosign
          image: ghcr.io/sigstore/cosign/cosign:v3.1.4
          args: ["sign", "--yes", "--allow-http-registry", "--key=/keys/cosign.key",
                 "--signing-config=/etc/sigstore/signing-config.json",
                 "--trusted-root=/etc/sigstore/trusted-root.json", "$IMAGE"]
          env:
            - name: COSIGN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: cosign-key
                  key: password
            - name: HOME
              value: /tmp
          volumeMounts:
            - name: keys
              mountPath: /keys
              readOnly: true
            - name: sigstore-trust
              mountPath: /etc/sigstore
              readOnly: true
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: keys
          secret:
            secretName: cosign-key
        - name: sigstore-trust
          configMap:
            name: sigstore-trust
        - name: tmp
          emptyDir: {}
YAML
run_job ci ci-sign-legacy || true
cat > "$TMP/verify-release.sh" <<'SCRIPT'
#!/bin/sh
# verify-release.sh IMAGE: exits 0 when IMAGE was signed by the CI pipeline.
exec cosign verify --allow-http-registry \
  --trusted-root /etc/sigstore/trusted-root.json \
  --key /etc/release/cosign.pub "$1"
SCRIPT
kubectl -n workstation create configmap verify-release --from-file=verify-release.sh="$TMP/verify-release.sh" \
  --from-file=cosign.pub="$TMP/cosign.pub" --dry-run=client -o yaml | kubectl apply -f -
rm -rf "$TMP"
