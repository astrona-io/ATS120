# Solution: Sign And Verify In A CI Job

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the Job `ci-sign` ran as `ci-builder` without any Secret and completed, the Job verifies with the `ci-builder` identity, and the release digest verifies for `ci/ci-builder`.

## Step 1: Check the inputs

```sh
kubectl -n ci get serviceaccount ci-builder
kubectl -n ci get configmap release-info -o jsonpath='{.data.image}'; echo
kubectl -n ci get configmap sigstore-trust -o jsonpath='{.data.oidc-issuer}'; echo
```

## Step 2: Write the Job

The init container signs; the main container verifies. Save this as `job-ci-sign.yaml`:

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
kubectl -n ci logs job/ci-sign -c verify
```

The Job completes, and the verify log shows the checks cosign made.

## Step 3: Verify from the deployment side and submit

```sh
kubectl -n workstation exec deploy/workstation -- sh -c "cosign verify --allow-http-registry \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder \
  --certificate-oidc-issuer \"\$(cat /etc/sigstore/oidc-issuer)\" \
  $(kubectl -n ci get configmap release-info -o jsonpath='{.data.image}') >/dev/null && echo verified"
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign only, verify by hand afterwards | The Job succeeds even when it signs as the wrong identity; the grader requires the verify step |
| Verify with `--certificate-identity-regexp '.*'` | The verify step can no longer catch a wrong identity |
| Mount the token into the verify container too | Not graded, but gives a step that only checks an identity of its own |

## Common mistakes

- Putting both steps in `containers`: they run at the same time, so verify may run before the signature exists.
- A token audience other than `sigstore`.
- Re-applying a changed Job instead of deleting and creating it.
