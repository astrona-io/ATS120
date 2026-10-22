# Solution: Move A Pipeline From A Signing Key To Keyless

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: no Secret or Job holds the key any more, the release digest verifies keylessly for `ci/ci-builder`, and the verification script verifies keylessly with the pinned identity.

## Step 1: Read the legacy pipeline

```sh
kubectl -n ci get secret cosign-key -o jsonpath='{.data}' | jq 'keys'
kubectl -n ci get job ci-sign-legacy -o jsonpath='{.spec.template.spec.containers[0].args}'; echo
kubectl -n workstation get configmap verify-release -o jsonpath='{.data.verify-release\.sh}'
```

The Secret holds `cosign.key` and `password`, the Job signs with `--key=/keys/cosign.key`, and the script verifies with `--key /etc/release/cosign.pub`. Every part depends on the key pair.

## Step 2: Build the keyless signer first

Change the signer before you remove anything, so the release is never left unsigned. Save this as `job-ci-sign.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ci-sign
  namespace: ci
spec:
  backoffLimit: 0
  template:
    spec:
      serviceAccountName: ci-builder
      restartPolicy: Never
      initContainers:
        - name: sign
          image: ghcr.io/sigstore/cosign/cosign:v3.1.4
          args:
            - sign
            - --yes
            - --allow-http-registry
            - --identity-token=/var/run/sigstore/token
            - --signing-config=/etc/sigstore/signing-config.json
            - --trusted-root=/etc/sigstore/trusted-root.json
            - $(IMAGE)
          env:
            - name: IMAGE
              valueFrom:
                configMapKeyRef:
                  name: release-info
                  key: image
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
      containers:
        - name: verify
          image: ghcr.io/sigstore/cosign/cosign:v3.1.4
          args:
            - verify
            - --allow-http-registry
            - --trusted-root=/etc/sigstore/trusted-root.json
            - --certificate-identity=https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder
            - --certificate-oidc-issuer=$(OIDC_ISSUER)
            - $(IMAGE)
          env:
            - name: IMAGE
              valueFrom:
                configMapKeyRef:
                  name: release-info
                  key: image
            - name: OIDC_ISSUER
              valueFrom:
                configMapKeyRef:
                  name: sigstore-trust
                  key: oidc-issuer
            - name: HOME
              value: /tmp
          volumeMounts:
            - name: sigstore-trust
              mountPath: /etc/sigstore
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
                  audience: sigstore
                  expirationSeconds: 600
        - name: tmp
          emptyDir: {}
```

Apply it:

```sh
kubectl apply -f job-ci-sign.yaml
```

Then check the result:

```sh
kubectl -n ci wait --for=condition=complete job/ci-sign --timeout=240s
```

## Step 3: Move the verification script

Save this as `verify-release.sh`:

```sh
#!/bin/sh
# verify-release.sh IMAGE: exits 0 only when IMAGE was signed keylessly by the
# service account ci-builder in the namespace ci, through this cluster's issuer.
exec cosign verify --allow-http-registry \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" "$1"
```

Store it, replacing the ConfigMap so the old public key goes with it:

```sh
kubectl -n workstation create configmap verify-release --from-file=verify-release.sh \
  --dry-run=client -o yaml | kubectl apply -f -
```

Test it on the release image:

```sh
kubectl -n workstation exec -i deploy/workstation -- sh -c 'cat > /tmp/verify-release.sh' < verify-release.sh
kubectl -n workstation exec deploy/workstation -- \
  sh /tmp/verify-release.sh "$(kubectl -n ci get configmap release-info -o jsonpath='{.data.image}')" >/dev/null && echo accepted
```

It prints `accepted`.

## Step 4: Remove the key and the legacy Job

Only now, with the keyless signer and the keyless check both working, remove the key:

```sh
kubectl -n ci delete job ci-sign-legacy
kubectl -n ci delete secret cosign-key
kubectl -n ci get jobs -o yaml | grep -c cosign-key
```

The last command prints `0`: no Job refers to the Secret any more.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep the Secret "in case we need it" | A key that exists can still sign; the review asked for its removal |
| Verify with both `--key` and the identity | cosign then checks the key, not the identity; the script must be keyless |
| Delete the key first | The release has no valid signature until the keyless signer runs |

## Common mistakes

- Using `kubectl apply` with the new script but keeping `cosign.pub` in the ConfigMap. Recreate it from the script only.
- Forgetting `serviceAccountName: ci-builder`: the Job signs as `ci/default`.
