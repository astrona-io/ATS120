# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Keyless flow

## Scenario

A verification service in the namespace `workstation` reads its trusted root from the ConfigMap `verifier-trust` (key `trusted-root.json`). Since the last change, it rejects the release bundle for `inventory-1.0.tar.gz`, which is stored in the ConfigMap `release-bundle` (the file is in `release-files`). The bundle is good: it verifies with the stack's own trust file.

## Your task

1. Find out why `cosign verify-blob` rejects the bundle with the trusted root in `verifier-trust`.
2. Repair the key `trusted-root.json` in `verifier-trust` so that the bundle verifies for the identity `https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation` and the cluster's issuer.
3. Check that the same bundle does not verify for any other identity.

## Constraints

- Verify with the trusted root only. Do not use `--insecure-ignore-tlog` or `--insecure-ignore-sct`.
- Do not change the bundle, the release file or the ConfigMap `sigstore-trust`.
- Do not sign the file again.

## Done when

- The bundle verifies with the trusted root in `verifier-trust` for the workstation identity and only for that identity.
- The trusted root has entries in `tlogs`, `certificateAuthorities` and `ctlogs`, and no Rekor or CT log key has an end time.
- The bundle, the release file and `sigstore-trust` are unchanged.
