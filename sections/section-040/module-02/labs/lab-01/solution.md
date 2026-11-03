# Solution: Configure A Verifier For A Provider

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the settings verify the digest, they are exact, and they reject other signers.

## Step 1: Get the digest

```sh
kubectl -n workstation exec deploy/workstation -- regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0
```

## Step 2: Discover the signer

Replace `<DIGEST>` with the result. The permissive flags are for reading only:

```sh
kubectl -n workstation exec deploy/workstation -- cosign verify --allow-http-registry \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity-regexp '.*' --certificate-oidc-issuer-regexp '.*' \
  registry.localtest.me:5001/inventory/podinfo@<DIGEST>
```

The output lists the certificate details, which name the service account `ci-builder` in the namespace `ci`. List the keys of the details with `jq '.[].optional | keys'` if you need to find the field names.

## Step 3: Read the issuer

```sh
kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.oidc-issuer}'
```

## Step 4: Write the settings

```sh
kubectl -n workstation create configmap verifier-settings \
  --from-literal=identity=https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder \
  --from-literal=issuer="$(kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.oidc-issuer}')" \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Step 5: Check, and test the negative case

```sh
kubectl -n workstation exec deploy/workstation -- sh -c 'cosign verify --allow-http-registry --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
  registry.localtest.me:5001/inventory/podinfo@<DIGEST> >/dev/null && echo accepted'
```

Run the same command with `release-bot` in the identity. It must fail.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Put `.*` in both values | The gate accepts every signer; the grader checks for exact values |
| Fix only the identity | The wrong issuer still fails |
| Sign the image again as release-bot | The settings then accept the wrong signer |

## Common mistakes

- Pinning the discovery output without checking that the signer is the one you meant.
- Copying the issuer from another cluster.
