# Overview: Trust Roots And Signing Configuration (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack, an image registry and the `workstation` pod, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack (Fulcio, Rekor, a certificate transparency log, Trillian). Fulcio trusts this cluster's service account tokens with the audience `sigstore`.
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with `inventory/podinfo:6.15.0`.
- The `workstation` pod with `cosign`, `rekor-cli`, `regctl`, `jq` and `openssl`, a projected token and the trust files in `/etc/sigstore`.
- The release file `/work/release/inventory-1.0.tar.gz`, also stored in the ConfigMap `release-files` in `workstation`.
- The ConfigMap `sigstore-trust` with `trusted-root.json`, `signing-config.json` and `oidc-issuer`, also mounted in `/etc/sigstore`.

## Practice tasks

- Print the number of entries in each list of `/etc/sigstore/trusted-root.json`.
- Copy the trusted root, empty its `ctlogs` list with `jq '.ctlogs = []'`, and verify a bundle with the copy. Read the error.
- Give the Rekor key an `end` time in the past in a copy and verify again.
- Change the Fulcio host in a copy of the signing configuration and read the error from `cosign sign-blob`.
