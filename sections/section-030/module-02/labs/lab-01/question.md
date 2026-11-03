# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Verification

## Scenario

A scanner step attested a vulnerability scan for the image `registry.localtest.me:5001/inventory/podinfo:6.15.0`. The attestation has the predicate type created by `cosign attest --type custom`. A deployment gate must know the digest the attestation is about, who signed it and how many critical findings it reports.

## Your task

1. Find the digest of the image tag and verify the attestation for the identity `https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation` and the cluster's issuer.
2. Decode the verified statement and read the `critical` value in its predicate.
3. Create a ConfigMap named `attestation-findings` in the namespace `workstation` with three keys: `digest` (the image digest), `critical` (the number of critical findings) and `identity` (the identity that signed it).

## Constraints

- Verify with the trusted root. Do not use `--insecure-ignore-tlog` or `--insecure-ignore-sct`.
- Read the values from the verified attestation. Do not create a new attestation.
- Use the exact identity. Do not use a regular expression.

## Done when

- `attestation-findings` has the digest the attestation is about.
- `attestation-findings` has the `critical` value of the verified predicate.
- `attestation-findings` names the signer identity.
