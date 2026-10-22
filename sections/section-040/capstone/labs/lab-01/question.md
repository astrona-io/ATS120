# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** CI

## Scenario

The release pipeline in the namespace `ci` signs with a key pair. The private key and its password are in the Secret `cosign-key`, the Job `ci-sign-legacy` signs the release digest with it, and the deployment check, the script `verify-release.sh` in the ConfigMap `verify-release` (namespace `workstation`), verifies with the matching public key. A security review asks you to remove the key and move the whole pipeline to keyless signing.

The release digest is in the ConfigMap `release-info` in `ci` (key `image`). The pipeline identity is the service account `ci-builder` in `ci`.

## Your task

1. Create a Job named `ci-sign` in `ci` that signs the release digest keylessly as `ci-builder`, with the private Sigstore stack.
2. Remove the Job `ci-sign-legacy` and the Secret `cosign-key`.
3. Change `verify-release.sh` so it verifies keylessly: it must accept the release image only when it was signed by `https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder` through the cluster's issuer. Store it in the ConfigMap `verify-release` under the same key.

## Constraints

- The new Job uses no Secret, key or password.
- `verify-release.sh` takes the image as its only argument, uses the private stack's trusted root (`/etc/sigstore/trusted-root.json`) and no longer uses `--key`.
- Do not change `release-info`, and do not push, retag or rebuild the image.

## Done when

- The Secret `cosign-key` is gone, and no Job in `ci` refers to it.
- The digest in `release-info` verifies keylessly for `ci/ci-builder` and the cluster's issuer.
- `verify-release.sh` accepts the release image, pins the `ci-builder` identity and uses no key.
