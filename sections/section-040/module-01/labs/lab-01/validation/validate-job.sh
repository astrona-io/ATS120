#!/usr/bin/env bash
# PASS when the Job ci-sign ran as ci-builder without a Secret
set -uo pipefail
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


# job_mentions_secrets NS JOB: true when the Job's pod template uses any Secret.
job_mentions_secrets() {
  kubectl -n "$1" get job "$2" -o jsonpath='{.spec.template.spec.volumes[*].secret.secretName}{.spec.template.spec.containers[*].env[*].valueFrom.secretKeyRef.name}{.spec.template.spec.initContainers[*].env[*].valueFrom.secretKeyRef.name}' 2>/dev/null | grep -q .
}

if ! kubectl -n ci get job ci-sign >/dev/null 2>&1; then
  echo "FAIL: the Job ci-sign does not exist in the namespace ci."
  exit 1
fi
SA="$(kubectl -n ci get job ci-sign -o jsonpath='{.spec.template.spec.serviceAccountName}')"
if [ "$SA" != "ci-builder" ]; then
  echo "FAIL: the Job ci-sign runs as '${SA:-default}', not as ci-builder."
  exit 1
fi
if [ "$(kubectl -n ci get job ci-sign -o jsonpath='{.status.succeeded}')" != "1" ]; then
  echo "FAIL: the Job ci-sign has not completed successfully."
  exit 1
fi
if job_mentions_secrets ci ci-sign; then
  echo "FAIL: the Job ci-sign uses a Secret. Keyless signing needs no stored key."
  exit 1
fi
echo "PASS: the Job ci-sign ran as ci-builder without any Secret."
exit 0
