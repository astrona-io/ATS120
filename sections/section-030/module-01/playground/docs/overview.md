# Overview: Verify Exactly Who Signed (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack and three signed images, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack (Fulcio, Rekor, a certificate transparency log, Trillian).
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with three signed images:

  | Image | Signed by |
  | --- | --- |
  | `inventory/podinfo:6.15.0` | `ci/release-bot` |
  | `inventory/podinfo:6.15.0-rc1` | `build/release-bot` |
  | `inventory/podinfo:6.15.0-hotfix` | `workstation/workstation` |

- The `workstation` pod with `cosign`, `regctl`, `jq` and `openssl`, the trust files in `/etc/sigstore`, and outbound internet for public images.

## Helpers

Open a shell in the workstation and paste these once. `check` runs `cosign verify` with the flags you give on all three images and prints which ones it accepts.

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
REG=registry.localtest.me:5001/inventory/podinfo
ISSUER="$(cat /etc/sigstore/oidc-issuer)"
check() {
  for tag in 6.15.0 6.15.0-rc1 6.15.0-hotfix; do
    if cosign verify --allow-http-registry --trusted-root /etc/sigstore/trusted-root.json \
         "$@" "$REG:$tag" >/dev/null 2>&1; then echo "$tag: accepted"; else echo "$tag: rejected"; fi
  done
}
```

Use it like this: `check --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot --certificate-oidc-issuer "$ISSUER"`.

## Practice tasks

- Write a regular expression that accepts both release bots but not the workstation, and one that accepts only `ci/release-bot`. Predict each result before you run `check`.
- Try an unescaped pattern such as `^https://kubernetes.io/namespaces/ci/` and think of an identity it would wrongly accept.
- Verify `ghcr.io/fluxcd/source-controller:v1.9.6` with the GitHub issuer and the repository flag, then swap the repository and read the error.
- Sign a file, copy it, its bundle and the trusted root to `/tmp/offline`, and verify from there.
