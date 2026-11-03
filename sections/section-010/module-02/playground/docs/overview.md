# Overview: Follow One Certificate Request (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack, an image registry and the `workstation` pod, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack (Fulcio, Rekor, a certificate transparency log, Trillian). Fulcio trusts this cluster's service account tokens with the audience `sigstore`.
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with `inventory/podinfo:6.15.0`.
- The `workstation` pod with `cosign`, `rekor-cli`, `regctl`, `jq` and `openssl`, a projected token and the trust files in `/etc/sigstore`.
- The release file `/work/release/inventory-1.0.tar.gz`, also stored in the ConfigMap `release-files` in `workstation`.

## Practice tasks

- Request Fulcio's configuration and trust bundle with `curl` and count the issuers.
- Sign the release file twice and run `rekor-cli search --sha sha256:<hash>` to find both entries.
- Extract the leaf certificate from a bundle and print its SCT extension with `openssl x509 -text`.
- Compare the `integratedTime` of a bundle entry with the certificate's `notBefore` and `notAfter`.
