# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Workload identity

## Scenario

The release of `inventory/podinfo` 6.15.0 is ready. The deployment team will only deploy images signed by the release pipeline's own identity, `ci/release-bot`, and they verify the digest recorded in the ConfigMap `release-info` in the namespace `ci` (key `image`).

The namespace `ci` already has the service account `release-bot` and the ConfigMap `sigstore-trust` with the private stack's trust files.

## Your task

1. Create a Job named `sign-release` in the namespace `ci` that runs as the service account `release-bot` and signs the image from `release-info` keylessly, with the private Sigstore stack.
2. Make sure the Job completes successfully.
3. Check that the release digest verifies for `https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot` and the cluster's issuer.

## Constraints

- **Keyless only.** The Job must not use any Secret or key.
- Sign the digest in `release-info`. Do not push, retag or rebuild the image, and do not change `release-info`.
- Do not sign from the workstation instead: the deployment team checks for `ci/release-bot`.

## Done when

- The Job `sign-release` in `ci` ran as `release-bot`, completed successfully and uses no Secret.
- The digest in `release-info` verifies for `ci/release-bot` and the cluster's issuer.
- The tag `6.15.0` still points at the original release digest.
