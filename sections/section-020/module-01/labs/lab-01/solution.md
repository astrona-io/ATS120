# Solution: Sign As The Release Bot

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the Job `sign-release` ran as `release-bot` without any Secret, the release digest verifies for `ci/release-bot`, and the release digest is unchanged.

## Step 1: Read what to sign

```sh
kubectl -n ci get configmap release-info -o jsonpath='{.data.image}'; echo
kubectl -n ci get serviceaccount release-bot
kubectl -n ci get configmap sigstore-trust
```

The image is the release by digest; the service account and the trust files exist.

## Step 2: Write the signing Job

Save this as `job-sign-release.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sign-release
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
kubectl apply -f job-sign-release.yaml
```

Then check the result:

```sh
kubectl -n ci wait --for=condition=complete job/sign-release --timeout=180s
kubectl -n ci logs job/sign-release
```

The Job completes, and the log shows the certificate request, the log upload and the push of the signature.

## Step 3: Verify the release identity

```sh
kubectl -n workstation exec deploy/workstation -- sh -c "cosign verify --allow-http-registry \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot \
  --certificate-oidc-issuer \"\$(cat /etc/sigstore/oidc-issuer)\" \
  $(kubectl -n ci get configmap release-info -o jsonpath='{.data.image}') >/dev/null && echo verified"
```

It prints `verified`.

## Step 4: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign from the workstation | The signature names `workstation/workstation`; the deployment check for `ci/release-bot` fails |
| Leave out `serviceAccountName` | The Job signs as `ci/default`, the wrong identity |
| Sign `podinfo:6.15.0` and push a new tag | The digest changes; the recorded release is not what you signed |

## Common mistakes

- Re-applying a changed Job: the pod template is immutable. Delete the Job first.
- A token audience other than `sigstore`: Fulcio refuses it and the Job fails.
- Forgetting the `HOME` variable and the `/tmp` volume: the cosign image cannot write its cache.
