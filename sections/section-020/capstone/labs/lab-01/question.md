# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Workload identity

## Scenario

The namespace `ci` releases two images: `inventory/podinfo` and `inventory/worker`. Each has its own signer and its own identity: `ci/release-bot` signs podinfo, `ci/worker-bot` signs worker. The release digests are in the ConfigMap `release-info` in `ci`, under the keys `podinfo` and `worker`.

Two signing Jobs, `sign-podinfo` and `sign-worker`, ran this morning. `sign-podinfo` reports success, but the deployment check for `ci/release-bot` still refuses podinfo. `sign-worker` failed.

## Your task

1. Find out which identity `sign-podinfo` really signed as, and why.
2. Find out why `sign-worker` failed. There is more than one problem with it.
3. Fix both Jobs so podinfo is signed by `ci/release-bot` and worker by `ci/worker-bot`, each by the digest in `release-info`.

## Constraints

- Keep the Job names `sign-podinfo` and `sign-worker`.
- **Keyless only.** No Secret, no key.
- Do not change `release-info`, and do not push, retag or rebuild the images.
- Do not sign either image from the workstation.

## Done when

- `sign-podinfo` runs as `release-bot`, and the podinfo digest verifies for `ci/release-bot`.
- `sign-worker` requests a token with the audience `sigstore`, and the worker digest verifies for `ci/worker-bot`.
- Both Jobs sign the digest from `release-info`, not a tag.
