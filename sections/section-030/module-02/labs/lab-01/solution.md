# Solution: Read And Check An Attestation

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the digest and the critical count in `attestation-findings`, the signer, and that the attestation is unchanged.

## Step 1: Get the digest

```sh
kubectl -n workstation exec deploy/workstation -- regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0
```

## Step 2: Verify the attestation

Replace `<DIGEST>` with the digest from the previous step:

```sh
kubectl -n workstation exec deploy/workstation -- sh -c '
  cosign verify-attestation --allow-http-registry --trusted-root /etc/sigstore/trusted-root.json --type custom \
    --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
    --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
    registry.localtest.me:5001/inventory/podinfo@<DIGEST> > /tmp/verified.json'
```

## Step 3: Read the predicate

```sh
kubectl -n workstation exec deploy/workstation -- sh -c "jq -r '.payload' /tmp/verified.json | base64 -d | jq '{predicateType, subject, predicate}'"
```

The predicate holds `critical`. If it appears inside a `Data` field, read the value from there.

## Step 4: Write the findings

```sh
kubectl -n workstation create configmap attestation-findings \
  --from-literal=digest=<DIGEST> \
  --from-literal=critical=<CRITICAL> \
  --from-literal=identity=https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation
```

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Read the `critical` value without verifying | The value is not tied to a signer |
| Use the tag instead of the digest | The grader compares the digest |
| Attest a new predicate with a value you like | The grader reads the original attestation |

## Common mistakes

- Forgetting `--type custom`, so cosign finds no attestation.
- Using the base64 text of the payload as the value.
