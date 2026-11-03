# Overview: Control Who Can Sign As A Workload (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack, an image registry and the `workstation` pod, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack (Fulcio, Rekor, a certificate transparency log, Trillian). Fulcio trusts this cluster's service account tokens with the audience `sigstore`.
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with `inventory/podinfo:6.15.0`.
- The `workstation` pod with `cosign`, `rekor-cli`, `regctl`, `jq` and `openssl`, a projected token and the trust files in `/etc/sigstore`.
- The namespace `ci` with the service account `release-bot`.
- The role bindings `pipeline-edit` (user `pipeline-user`, cluster role `edit`) and `dev-view` (user `dev-user`, cluster role `view`).

## Practice tasks

- Mint a token with `kubectl -n ci create token release-bot --audience sigstore --duration 10m` and decode its payload.
- Run `kubectl auth can-i create pods -n ci --as dev-user` for both users and for `serviceaccounts/token`.
- Create the namespace `staging` with a service account `release-bot` and compare the token subjects.
- List the role bindings and the cluster role bindings that reach `ci`.
