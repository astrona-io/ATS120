# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Verification

## Scenario

The release image `registry.localtest.me:5001/inventory/podinfo:6.15.0` was signed by a CI Job in the namespace `ci`. A deployment gate reads its verification values from the ConfigMap `verifier-settings` in the namespace `workstation` (keys `identity` and `issuer`). The gate rejects the image. Nobody remembers which pipeline signed it or which issuer vouched for it.

## Your task

1. Find out which identity signed the image digest and which issuer vouched for it. Use a discovery command for reading only.
2. Write the exact identity and the exact issuer into `verifier-settings`.
3. Check that the digest verifies with the new values, and that it does not verify for `ci/release-bot`.

## Constraints

- Both values must be exact strings. Do not use regular expressions or wildcards in `verifier-settings`.
- Do not use `--insecure-ignore-tlog` or `--insecure-ignore-sct`.
- Do not sign the image again.

## Done when

- `cosign verify` with the identity and issuer from `verifier-settings` accepts the release digest.
- The identity and the issuer are exact strings for the signer and for this cluster.
- The settings reject `ci/release-bot` and a foreign issuer.
