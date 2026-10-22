# Prerequisites

Before starting this lab you should be able to:

- Use `kubectl` to create, inspect and delete objects in a namespace.
- Run commands in a pod with `kubectl exec`.
- Read a shell script and a regular expression.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- A private Sigstore stack: Fulcio, Rekor, a certificate transparency log and
  Trillian. Fulcio trusts this cluster's service account tokens.
- An OCI registry at `registry.localtest.me:5001` (plain HTTP, lab-only).
- The `workstation` pod with `cosign` v3.1.4, `rekor-cli`, `regctl`, `jq` and
  `openssl`, the trust files in `/etc/sigstore` and a token in
  `/var/run/sigstore/token`.
- The namespaces `workstation`, `ci` and `build`, prepared as the task describes.

## Working rules

- Everything is graded on the **final state**, so leave your fix in place.
- Change one thing at a time and check it with `cosign verify`.
- Never verify with `--insecure-ignore-tlog` or `--insecure-ignore-sct`.
