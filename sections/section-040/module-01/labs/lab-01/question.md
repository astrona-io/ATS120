# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** CI

## Scenario

The inventory team moves its release signing into the cluster. The release digest is recorded in the ConfigMap `release-info` in the namespace `ci` (key `image`). The pipeline identity is the service account `ci-builder` in `ci`, and the deployment check will accept only signatures from that identity.

The namespace `ci` also has the ConfigMap `sigstore-trust` with `trusted-root.json`, `signing-config.json` and `oidc-issuer`.

## Your task

Create a Job named `ci-sign` in the namespace `ci` that:

1. runs as the service account `ci-builder`;
2. signs the image from `release-info` keylessly with the private Sigstore stack;
3. verifies the signature in the same Job, after signing, with the identity `https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder` and the cluster's issuer, so the Job fails if the signature is wrong;
4. completes successfully.

## Constraints

- **Keyless only.** The Job must not use any Secret, key or password.
- Sign and verify the digest from `release-info`. Do not push, retag or rebuild the image.
- Do not sign from the workstation.

## Done when

- The Job `ci-sign` ran as `ci-builder`, completed successfully and uses no Secret.
- The Job has a step that runs `cosign verify` with the `ci-builder` identity.
- The digest in `release-info` verifies for `ci/ci-builder` and the cluster's issuer.
