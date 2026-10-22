# Solution: Repair A Keyless Signing Setup

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

There are three independent faults: the published bundle was signed with a long-lived key, the signing configuration names a Fulcio Service that does not exist, and the workstation's token is issued for the wrong audience. The grader checks each fix and then verifies a new keyless bundle.

## Step 1: Read the published bundle

Copy the bundle out of the ConfigMap and look at its verification material:

```sh
kubectl -n workstation get configmap release-bundle \
  -o jsonpath='{.data.inventory-1\.0\.tar\.gz\.sigstore\.json}' > published.json
jq '.verificationMaterial | keys' published.json
```

There is no `certificate` key. The bundle holds a `publicKey` hint instead: it was signed with a key pair. A consumer would need that public key, which defeats keyless signing. The bundle must be replaced, but first the workstation must be able to sign keylessly again.

## Step 2: Try to sign and read the error

```sh
kubectl -n workstation exec deploy/workstation -- cosign sign-blob --yes \
  --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --bundle /tmp/test.sigstore.json /work/release/inventory-1.0.tar.gz
```

The command fails when cosign contacts the certificate authority. Look at which address it uses:

```sh
kubectl -n workstation exec deploy/workstation -- jq '[.caUrls[].url]' /etc/sigstore/signing-config.json
kubectl -n fulcio-system get service
```

The signing configuration names `http://fulcio.fulcio-system.svc`, but the Service is `fulcio-server`.

## Step 3: Fix the signing configuration

Copy the three keys of the ConfigMap, fix the address, and write the ConfigMap back:

```sh
kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.trusted-root\.json}' > trusted-root.json
kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.signing-config\.json}' > signing-config.json
kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.oidc-issuer}' > oidc-issuer
sed -i.bak 's#http://fulcio.fulcio-system.svc#http://fulcio-server.fulcio-system.svc#g' signing-config.json
kubectl -n workstation create configmap sigstore-trust \
  --from-file=trusted-root.json --from-file=signing-config.json --from-file=oidc-issuer \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Step 4: Read the token's audience

Sign again. Now cosign reaches Fulcio, but Fulcio refuses the token. Read the token's claims:

```sh
kubectl -n workstation exec deploy/workstation -- sh -c \
  "cut -d. -f2 /var/run/sigstore/token | tr '_-' '/+' | awk '{ while (length(\$0) % 4) \$0 = \$0 \"=\"; print }' | base64 -d | jq '{iss, aud}'"
```

The audience is `sigstore-dev`. Fulcio accepts only tokens for its client ID, `sigstore`.

## Step 5: Fix the audience

The audience comes from the pod spec. Patch the Deployment's projected token volume:

```sh
kubectl -n workstation get deployment workstation \
  -o jsonpath='{range .spec.template.spec.volumes[*]}{.name}{"\n"}{end}'
kubectl -n workstation patch deployment workstation --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/volumes/3/projected/sources/0/serviceAccountToken/audience","value":"sigstore"}]'
kubectl -n workstation rollout status deployment/workstation
```

The first command lists the volumes so you can confirm that `sigstore-token` is the fourth one (index 3). The new pod also reads the fixed ConfigMap. The restart emptied `/work`, so put the release file back from `release-files`:

```sh
kubectl -n workstation get configmap release-files -o jsonpath='{.binaryData.inventory-1\.0\.tar\.gz}' \
  | base64 -d | kubectl -n workstation exec -i deploy/workstation -- \
    sh -c 'mkdir -p /work/release && cat > /work/release/inventory-1.0.tar.gz'
```

## Step 6: Sign keylessly and replace the bundle

```sh
kubectl -n workstation exec deploy/workstation -- cosign sign-blob --yes \
  --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --bundle /work/release/inventory-1.0.tar.gz.sigstore.json \
  /work/release/inventory-1.0.tar.gz
kubectl -n workstation exec deploy/workstation -- \
  cat /work/release/inventory-1.0.tar.gz.sigstore.json > inventory-1.0.tar.gz.sigstore.json
kubectl -n workstation create configmap release-bundle \
  --from-file=inventory-1.0.tar.gz.sigstore.json=inventory-1.0.tar.gz.sigstore.json \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Step 7: Verify and submit

```sh
kubectl -n workstation exec deploy/workstation -- sh -c 'cosign verify-blob \
  --bundle /work/release/inventory-1.0.tar.gz.sigstore.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
  /work/release/inventory-1.0.tar.gz'
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Publish the public key with the old bundle | Consumers verify against a key nobody controls any more; the task asks for keyless |
| Rebuild the trust files from scratch | Not needed, and easy to get wrong; only one URL was broken |
| Add `sigstore-dev` to Fulcio's configuration | Changes the certificate authority to fit one broken client |

## Common mistakes

- Fixing the ConfigMap but not restarting the pod: a running pod may keep the old file content for a while.
- Forgetting to put the release file back after the restart; `/work` is not persistent.
- Replacing only the bundle in the pod, not in the ConfigMap.
