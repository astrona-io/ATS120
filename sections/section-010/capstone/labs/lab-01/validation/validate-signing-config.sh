#!/usr/bin/env bash
# PASS when signing-config.json names the running Fulcio
set -uo pipefail

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
# load_release FILES_CM BUNDLE_CM: puts the release file and its bundle in /tmp/grade.
load_release() {
  ws sh -c 'rm -rf /tmp/grade && mkdir -p /tmp/grade'
  kubectl -n workstation get configmap "$1" -o jsonpath='{.binaryData.inventory-1\.0\.tar\.gz}' \
    | base64 -d | ws sh -c 'cat > /tmp/grade/inventory-1.0.tar.gz'
  kubectl -n workstation get configmap "$2" -o jsonpath='{.data.inventory-1\.0\.tar\.gz\.sigstore\.json}' \
    | ws sh -c 'cat > /tmp/grade/bundle.json'
}
bundle_san() {
  ws sh -c 'jq -r ".verificationMaterial.certificate.rawBytes // .verificationMaterial.x509CertificateChain.certificates[0].rawBytes // empty" /tmp/grade/bundle.json \
    | base64 -d 2>/dev/null | openssl x509 -inform DER -noout -ext subjectAltName 2>/dev/null'
}


CFG="$(kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.signing-config\.json}')"
if ! printf '%s' "$CFG" | grep -q 'http://fulcio-server.fulcio-system.svc'; then
  echo "FAIL: signing-config.json in sigstore-trust does not name the Fulcio Service fulcio-server.fulcio-system.svc."
  exit 1
fi
if printf '%s' "$CFG" | grep -q 'http://fulcio.fulcio-system.svc'; then
  echo "FAIL: signing-config.json still names the Service fulcio.fulcio-system.svc, which does not exist."
  exit 1
fi
echo "PASS: signing-config.json names the running Fulcio."
exit 0
