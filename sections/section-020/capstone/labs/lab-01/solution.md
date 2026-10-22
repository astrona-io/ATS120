# Solution: Sign Two Images With Their Own Identities

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

There are three faults: `sign-podinfo` runs as the `default` service account, `sign-worker` requests a token for the audience `sts.amazonaws.com`, and `sign-worker` names the tag `worker:1.0` instead of the digest. The grader verifies each image for its own identity and checks the Jobs' specs.

## Step 1: Find the identity of the podinfo signature

```sh
kubectl -n ci get job sign-podinfo -o jsonpath='{.spec.template.spec.serviceAccountName}'; echo
```

The output is empty: no service account is set, so the pod ran as `default`. The Job signed successfully, as `https://kubernetes.io/namespaces/ci/serviceaccounts/default`. Confirm it:

```sh
PODINFO="$(kubectl -n ci get configmap release-info -o jsonpath='{.data.podinfo}')"
kubectl -n workstation exec deploy/workstation -- sh -c "cosign verify --allow-http-registry \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/default \
  --certificate-oidc-issuer \"\$(cat /etc/sigstore/oidc-issuer)\" $PODINFO >/dev/null && echo 'signed as ci/default'"
```

It prints `signed as ci/default`. That signature stays on the image, which is harmless: the deployment check names `ci/release-bot` and ignores it.

## Step 2: Find why the worker signer failed

```sh
kubectl -n ci logs job/sign-worker
kubectl -n ci get job sign-worker -o jsonpath='{.spec.template.spec.volumes[?(@.name=="sigstore-token")].projected.sources[0].serviceAccountToken.audience}'; echo
kubectl -n ci get job sign-worker -o jsonpath='{.spec.template.spec.containers[0].args}'; echo
```

The log shows that Fulcio refused the token. The audience is `sts.amazonaws.com`, not `sigstore`. The arguments also end with `registry.localtest.me:5001/inventory/worker:1.0`, a tag, while `release-info` holds a digest.

## Step 3: Recreate the podinfo signer

A Job's pod template cannot be changed, so delete and recreate each Job. Save this as `job-sign-podinfo.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sign-podinfo
  namespace: ci
spec:
  backoffLimit: 0
  template:
    spec:
      serviceAccountName: release-bot
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
            - $(IMAGE)
          env:
            - name: IMAGE
              valueFrom:
                configMapKeyRef:
                  name: release-info
                  key: podinfo
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
                  audience: sigstore
                  expirationSeconds: 600
        - name: tmp
          emptyDir: {}
```

Apply it:

```sh
kubectl -n ci delete job sign-podinfo
kubectl apply -f job-sign-podinfo.yaml
```

## Step 4: Recreate the worker signer

Save this as `job-sign-worker.yaml`. It differs from the podinfo Job in the name, the service account and the `release-info` key:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sign-worker
  namespace: ci
spec:
  backoffLimit: 0
  template:
    spec:
      serviceAccountName: worker-bot
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
            - $(IMAGE)
          env:
            - name: IMAGE
              valueFrom:
                configMapKeyRef:
                  name: release-info
                  key: worker
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
                  audience: sigstore
                  expirationSeconds: 600
        - name: tmp
          emptyDir: {}
```

Apply it:

```sh
kubectl -n ci delete job sign-worker
kubectl apply -f job-sign-worker.yaml
```

Then check both Jobs:

```sh
kubectl -n ci wait --for=condition=complete job/sign-podinfo job/sign-worker --timeout=180s
```

## Step 5: Verify each identity and submit

```sh
for pair in podinfo:release-bot worker:worker-bot; do
  key="${pair%%:*}"; sa="${pair#*:}"
  image="$(kubectl -n ci get configmap release-info -o jsonpath="{.data.$key}")"
  kubectl -n workstation exec deploy/workstation -- sh -c "cosign verify --allow-http-registry \
    --trusted-root /etc/sigstore/trusted-root.json \
    --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/$sa \
    --certificate-oidc-issuer \"\$(cat /etc/sigstore/oidc-issuer)\" $image >/dev/null && echo '$key verified for ci/$sa'"
done
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign both images as `release-bot` | worker verifies for the wrong identity; the check for `ci/worker-bot` fails |
| Delete the `ci/default` signature | Not needed: verification for `ci/release-bot` ignores it |
| Keep the tag in `sign-worker` | The signature covers whatever the tag points at when the Job runs |

## Common mistakes

- Changing only `serviceAccountName` but keeping the wrong audience: Fulcio still refuses the token.
- Using one `release-info` key for both Jobs.
