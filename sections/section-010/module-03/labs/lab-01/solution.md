# Solution: Repair A Verifier's Trusted Root

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the bundle verifies with `verifier-trust` and only for one identity, the trusted root is complete, and the published bundle is unchanged.

## Step 1: Read the verifier's trusted root

Print the shape of the file in the ConfigMap:

```sh
kubectl -n workstation get configmap verifier-trust -o jsonpath='{.data.trusted-root\.json}' \
  | jq '{tlogs: (.tlogs | length), certificateAuthorities: (.certificateAuthorities | length), ctlogs: (.ctlogs | length), tlogValidFor: .tlogs[0].publicKey.validFor}'
```

Two faults show. The `ctlogs` list is empty, so the certificate's signed certificate timestamp has no key to check against. The Rekor key has an `end` time in the past, so no Rekor key is valid at the time of the signature.

## Step 2: Compare with the stack's trusted root

```sh
kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.trusted-root\.json}' \
  | jq '{tlogs: (.tlogs | length), ctlogs: (.ctlogs | length), tlogValidFor: .tlogs[0].publicKey.validFor}'
```

The stack's own file has one CT log and a Rekor range with only a `start`.

## Step 3: Replace the verifier's file

```sh
kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.trusted-root\.json}' > trusted-root.json
kubectl -n workstation create configmap verifier-trust --from-file=trusted-root.json=trusted-root.json \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Step 4: Verify

Pipe the files into the workstation and verify:

```sh
kubectl -n workstation get configmap release-bundle -o jsonpath='{.data.inventory-1\.0\.tar\.gz\.sigstore\.json}' \
  | kubectl -n workstation exec -i deploy/workstation -- sh -c 'cat > /tmp/bundle.json'
kubectl -n workstation get configmap verifier-trust -o jsonpath='{.data.trusted-root\.json}' \
  | kubectl -n workstation exec -i deploy/workstation -- sh -c 'cat > /tmp/verifier-root.json'
kubectl -n workstation exec deploy/workstation -- cosign verify-blob --bundle /tmp/bundle.json \
  --trusted-root /tmp/verifier-root.json \
  --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
  --certificate-oidc-issuer "$(kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.oidc-issuer}')" \
  /work/release/inventory-1.0.tar.gz
```

The command prints `Verified OK`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Verify with `--insecure-ignore-tlog` | The grader reads the trusted root and still finds the faults |
| Delete the `end` field only | The empty `ctlogs` list still fails the certificate timestamp check |
| Sign the file again | Does not repair the trusted root |

## Common mistakes

- Editing `sigstore-trust` instead of `verifier-trust`.
- Forgetting that a ConfigMap key name with a dot needs `\.` in the jsonpath.
