# Overview: Sign Without A Long-Lived Key (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private Sigstore stack, an image registry and the `workstation` pod, then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster. `kubectl` is already pointed at it.
- A private Sigstore stack: Fulcio in `fulcio-system`, Rekor in `rekor-system`, a certificate transparency log in `ctlog-system`, and Trillian with MySQL in `trillian-system`. Fulcio trusts this cluster's service account tokens with the audience `sigstore`.
- An image registry at `registry.localtest.me:5001` (plain HTTP, lab-only) with the image `inventory/podinfo:6.15.0`.
- The `workstation` pod (namespace `workstation`, service account `workstation`) with `cosign` v3.1.4, `rekor-cli`, `regctl`, `jq` and `openssl`.

  | Path | What it is |
  | --- | --- |
  | `/var/run/sigstore/token` | Projected token, audience `sigstore` |
  | `/etc/sigstore/trusted-root.json` | What a verifier trusts |
  | `/etc/sigstore/signing-config.json` | Which Fulcio and Rekor a signer uses |
  | `/etc/sigstore/oidc-issuer` | The issuer URL of this cluster's tokens |
  | `/work/release/inventory-1.0.tar.gz` | A file to sign |

## Helpers

Open a shell in the workstation and paste these once. `token_claims` prints the claims of the workstation's token. `sign_file` signs a file keylessly and writes its bundle next to it. `verify_file` verifies a file for the workstation identity.

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
token_claims() {
  cut -d. -f2 /var/run/sigstore/token | tr '_-' '/+' \
    | awk '{ while (length($0) % 4) $0 = $0 "="; print }' | base64 -d | jq .
}
sign_file() {
  cosign sign-blob --yes --identity-token /var/run/sigstore/token \
    --signing-config /etc/sigstore/signing-config.json \
    --trusted-root /etc/sigstore/trusted-root.json \
    --bundle "$1.sigstore.json" "$1"
}
verify_file() {
  cosign verify-blob --bundle "$1.sigstore.json" \
    --trusted-root /etc/sigstore/trusted-root.json \
    --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
    --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" "$1"
}
```

Use them like this: `token_claims`, `sign_file /work/release/inventory-1.0.tar.gz`, `verify_file /work/release/inventory-1.0.tar.gz`.

## Practice tasks

- Print the token claims and compare `iss` with the content of `/etc/sigstore/oidc-issuer`.
- Sign the release file, then change one byte of it (`echo x >> /work/release/inventory-1.0.tar.gz`) and verify again. Predict the result first.
- Sign a second file and compare the two certificates' `notBefore` and `notAfter` dates.
- Verify a bundle with the identity of another service account and read the error.
- Look up a bundle's log entry in Rekor with `rekor-cli get --rekor_server http://rekor-server.rekor-system.svc --log-index <N>`, using the `logIndex` from the bundle.
