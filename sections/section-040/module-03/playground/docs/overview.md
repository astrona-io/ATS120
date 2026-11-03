# Overview: Operate Keyless Signing (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack, an image registry and the `workstation` pod, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack (Fulcio, Rekor, a certificate transparency log, Trillian). Fulcio trusts this cluster's service account tokens with the audience `sigstore`.
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with `inventory/podinfo:6.15.0`.
- The `workstation` pod with `cosign`, `rekor-cli`, `regctl`, `jq` and `openssl`, a projected token and the trust files in `/etc/sigstore`.
- The service accounts `release-bot` and `ci-builder`, and the ConfigMap `release-info`, in the namespace `ci`.
- The ConfigMap `sigstore-trust` in `workstation` and `ci`.

## Practice tasks

- Create a key pair in the workstation, sign the release image with it and keyless, and verify both.
- Create a Job with a missing service account and read its events with `kubectl describe job`.
- Create a Job that signs with the audience `fulcio` and read the log.
- Compare the hash of `trusted-root.json` in `workstation` and `ci`.
