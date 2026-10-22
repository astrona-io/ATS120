# Overview: Sign In CI Without A Stored Key (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack, an image registry and a CI namespace, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack (Fulcio, Rekor, a certificate transparency log, Trillian). Fulcio trusts this cluster's service account tokens with the audience `sigstore`.
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with `inventory/podinfo:6.15.0`.
- The namespace `ci` with the service accounts `release-bot` and `ci-builder`, the ConfigMap `release-info` (key `image`: the release image by digest) and the ConfigMap `sigstore-trust`.
- The `workstation` pod with `cosign`, `regctl` and `jq`, and outbound internet for public images.

## Helpers

Paste these once in each new terminal. `job_logs` prints the logs of every container of a Job in `ci`. `verify_as` verifies the release image for one service account: `verify_as ci ci-builder`.

```sh
job_logs() {
  for c in $(kubectl -n ci get job "$1" -o jsonpath='{.spec.template.spec.initContainers[*].name} {.spec.template.spec.containers[*].name}'); do
    echo "== $c"; kubectl -n ci logs "job/$1" -c "$c"
  done
}
verify_as() {
  kubectl -n workstation exec deploy/workstation -- sh -c "cosign verify --allow-http-registry \
    --trusted-root /etc/sigstore/trusted-root.json \
    --certificate-identity https://kubernetes.io/namespaces/$1/serviceaccounts/$2 \
    --certificate-oidc-issuer \"\$(cat /etc/sigstore/oidc-issuer)\" \
    $(kubectl -n ci get configmap release-info -o jsonpath='{.data.image}') >/dev/null && echo 'verified for $1/$2'"
}
```

## Practice tasks

- Build the sign-and-verify Job, then break its verify step on purpose by naming `release-bot` instead of `ci-builder`, and read `job_logs ci-sign`.
- Run the same Job as `release-bot` and check with `verify_as` which identity signed.
- Verify `ghcr.io/fluxcd/source-controller:v1.9.6` in the workstation with `--certificate-github-workflow-trigger push` and with `pull_request`, and compare.
