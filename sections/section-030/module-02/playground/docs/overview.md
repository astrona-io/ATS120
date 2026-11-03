# Overview: Verify Claims About An Image (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack, an image registry and the `workstation` pod, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack (Fulcio, Rekor, a certificate transparency log, Trillian). Fulcio trusts this cluster's service account tokens with the audience `sigstore`.
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with `inventory/podinfo:6.15.0`.
- The `workstation` pod with `cosign`, `rekor-cli`, `regctl`, `jq` and `openssl`, a projected token and the trust files in `/etc/sigstore`.
- The image `inventory/podinfo:6.15.0` in the registry, without any attestation.

## Practice tasks

- Write a predicate file and run `cosign attest --type custom` for the image digest.
- Run `cosign verify-attestation --type custom` with the workstation identity, then with the identity `ci/release-bot`, and compare.
- Decode the payload with `base64 -d` and print `predicateType`, `subject` and `predicate` with `jq`.
- Attest a second predicate and see that both attestations pass the verification.
