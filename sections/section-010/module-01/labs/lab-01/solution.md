# Solution: Sign A Release File Keylessly And Publish Its Bundle

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the ConfigMap `release-bundle` holds a bundle with a log entry, the bundle's certificate names the workstation identity, and `cosign verify-blob` accepts the bundle for that identity only.

## Step 1: Check the token and the trust files

Signing keylessly needs a token for the audience `sigstore` and the two trust files. Check that all three are in place:

```sh
kubectl -n workstation exec deploy/workstation -- ls -l /var/run/sigstore/token /etc/sigstore/
```

You see the token file and `trusted-root.json`, `signing-config.json` and `oidc-issuer`.

## Step 2: Sign the release file

Sign the file with the token, the signing configuration and the trusted root, and write the bundle next to it:

```sh
kubectl -n workstation exec deploy/workstation -- cosign sign-blob --yes \
  --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --bundle /work/release/inventory-1.0.tar.gz.sigstore.json \
  /work/release/inventory-1.0.tar.gz
```

cosign gets a certificate from Fulcio, uploads the signature to Rekor and writes the bundle.

## Step 3: Read the identity in the certificate

Before you publish, check that the certificate names the right identity:

```sh
kubectl -n workstation exec deploy/workstation -- sh -c \
  'jq -r ".verificationMaterial.certificate.rawBytes" /work/release/inventory-1.0.tar.gz.sigstore.json \
   | base64 -d | openssl x509 -inform DER -noout -ext subjectAltName'
```

The SAN is `URI:https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation`.

## Step 4: Publish the bundle

Copy the bundle out of the pod and store it in a ConfigMap:

```sh
kubectl -n workstation exec deploy/workstation -- \
  cat /work/release/inventory-1.0.tar.gz.sigstore.json > inventory-1.0.tar.gz.sigstore.json
kubectl -n workstation create configmap release-bundle \
  --from-file=inventory-1.0.tar.gz.sigstore.json=inventory-1.0.tar.gz.sigstore.json
```

## Step 5: Verify like a consumer

Verify the file with the published bundle, the exact identity and the cluster's issuer:

```sh
kubectl -n workstation exec deploy/workstation -- sh -c 'cosign verify-blob \
  --bundle /work/release/inventory-1.0.tar.gz.sigstore.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
  /work/release/inventory-1.0.tar.gz'
```

cosign reports that the verification succeeded.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign with a key pair | The bundle holds a public key hint instead of a certificate; consumers would need your public key |
| Verify with `--certificate-identity-regexp '.*'` | Any identity passes; the check proves nothing about who signed |
| Turn off the log upload | No trusted signing time; the expired certificate proves nothing |

## Common mistakes

- Running `sign-blob` without `--signing-config`: cosign then uses the public-good instance and asks for a browser login.
- Forgetting `--bundle`: with a signing configuration, cosign needs a bundle file to write the result to.
- Creating the ConfigMap with a different key name. The key must be `inventory-1.0.tar.gz.sigstore.json`.

## Practice on your own

- Verify the bundle with `--certificate-identity` set to another service account and read the error.
- Find the bundle's entry in Rekor with `rekor-cli` and its `logIndex`.
