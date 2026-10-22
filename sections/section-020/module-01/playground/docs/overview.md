# Overview: Sign As A Kubernetes Workload (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack, an image registry and the `workstation` pod, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack (Fulcio, Rekor, a certificate transparency log, Trillian). Fulcio trusts this cluster's service account tokens with the audience `sigstore`.
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with `inventory/podinfo:6.15.0`.
- The `workstation` pod with `cosign`, `regctl` and `jq`, a projected token and the trust files in `/etc/sigstore`.
- The namespace `ci` with the service account `release-bot`, the ConfigMap `sigstore-trust` and the ConfigMap `release-info` (key `image`: the release image by digest).

## Helpers

Paste these once in each new terminal. `release_image` prints the release image by digest. `verify_as` verifies the release image for one service account: `verify_as ci release-bot`.

```sh
release_image() { kubectl -n ci get configmap release-info -o jsonpath='{.data.image}'; }
verify_as() {
  kubectl -n workstation exec deploy/workstation -- sh -c "cosign verify --allow-http-registry \
    --trusted-root /etc/sigstore/trusted-root.json \
    --certificate-identity https://kubernetes.io/namespaces/$1/serviceaccounts/$2 \
    --certificate-oidc-issuer \"\$(cat /etc/sigstore/oidc-issuer)\" $(release_image) >/dev/null && echo 'verified for $1/$2'"
}
```

## Practice tasks

- Sign the release image from the workstation, then run `verify_as workstation workstation` and `verify_as ci release-bot`. Predict both results first.
- Create a signing Job without `serviceAccountName` and check which identity its signature has with `verify_as ci default`.
- Change the Job's token audience to `api` and read the Job's log after it fails.
- Run `cosign tree --allow-http-registry` on the release image in the workstation after each signature and count the attached artifacts.
