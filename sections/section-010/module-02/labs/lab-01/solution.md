# Solution: Find The Rekor Entry Of A Release Signature

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: `logIndex` matches the bundle and Rekor has the entry, `identity` matches the certificate, and the bundle is unchanged.

## Step 1: Read the log index

The workstation pod has no `kubectl`, so read the bundle from the ConfigMap on your machine and pipe it into the pod. 

```sh
kubectl -n workstation get configmap release-bundle -o jsonpath='{.data.inventory-1\.0\.tar\.gz\.sigstore\.json}' \
  | kubectl -n workstation exec -i deploy/workstation -- sh -c 'cat > /tmp/bundle.json'
kubectl -n workstation exec deploy/workstation -- jq '.verificationMaterial.tlogEntries[0] | {logIndex, integratedTime}' /tmp/bundle.json
```

The `logIndex` is the number you need.

## Step 2: Check the entry in Rekor

```sh
kubectl -n workstation exec deploy/workstation -- rekor-cli get --rekor_server http://rekor-server.rekor-system.svc --log-index <LOGINDEX>
```

Replace `<LOGINDEX>` with the number. Rekor prints the entry with the same integrated time.

## Step 3: Read the identity

```sh
kubectl -n workstation exec deploy/workstation -- sh -c "jq -r '.verificationMaterial.certificate.rawBytes // .verificationMaterial.x509CertificateChain.certificates[0].rawBytes' /tmp/bundle.json | base64 -d | openssl x509 -inform DER -noout -ext subjectAltName"
```

The line starting with `URI:` holds the identity, `https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation`.

## Step 4: Write the findings

```sh
kubectl -n workstation create configmap rekor-findings \
  --from-literal=logIndex=<LOGINDEX> \
  --from-literal=identity=https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation
```

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign the file again and note the new index | The index does not match the published bundle |
| Search Rekor by hash and take the first result | The file may have several entries; only the bundle's index is correct |
| Type the identity from memory | The grader compares it with the certificate in the bundle |

## Common mistakes

- Using the integrated time instead of the log index.
- Reading the bundle from the workstation file system: the published bundle is in the ConfigMap.
