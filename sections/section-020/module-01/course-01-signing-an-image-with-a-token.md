# Signing An Image With A Service Account Token

Signing a container image keylessly looks almost the same as signing a file, with two differences. The thing that gets signed is the image's digest, and the signature does not land in a local file but in the registry, next to the image. This part signs the example image from the workstation, finds the signature in the registry, and verifies it for one exact identity.

## Tags move, digests do not

A **tag** such as `6.15.0` is a name that points at an image. Anyone with push rights can move it to other content. A **digest** such as `sha256:4f2c...` is the SHA-256 hash of the image manifest, so it names one exact content and cannot point anywhere else. A signature must cover the digest, or it would follow the tag to whatever content the tag points at next.

<!-- astrona:playground:renew -->

Look up the digest the tag points at now. `regctl` is a registry client in the workstation:

```sh
kubectl -n workstation exec deploy/workstation -- \
  regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0
```

The output is one `sha256:` value. The ConfigMap `release-info` in `ci` holds the same image by digest, which is the form every signing step in this module uses:

```sh
kubectl -n ci get configmap release-info -o jsonpath='{.data.image}'; echo
```

The value is `registry.localtest.me:5001/inventory/podinfo@sha256:` followed by the same hash. If you give cosign a tag, it looks up the digest itself and warns you, because the tag might have moved between your build and your signature.

## Signing from the workstation

Sign the image keylessly as the workstation. The flags are the same as for a file, plus `--allow-http-registry`, because the lab registry uses plain HTTP; a real registry uses HTTPS and needs no such flag. Open a shell in the workstation first:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Then sign the release image by digest:

```sh
IMAGE="registry.localtest.me:5001/inventory/podinfo@$(regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0)"
cosign sign --yes --allow-http-registry \
  --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  "$IMAGE"
```

cosign gets a certificate from Fulcio, uploads the signature to Rekor and pushes the result to the registry. Nothing changes in the image itself: its digest stays the same.

## Where the signature lives

cosign v3 stores the signature as a Sigstore bundle in the registry, as a separate artifact that refers to the image digest. A verifier finds it by asking the registry which artifacts refer to that digest. `cosign tree` shows what is attached to an image:

```sh
cosign tree --allow-http-registry "$IMAGE"
```

The output lists the image and, under it, the attached signature artifact. If you sign the same digest again later, a second signature appears next to the first; signatures add up, they never replace each other. Older cosign versions used a tag named after the digest, ending in `.sig`, and you may still meet that layout in older registries.

## Verifying for one identity

`cosign verify` checks image signatures. Like `verify-blob`, it needs the trusted root, the exact identity and the issuer:

```sh
cosign verify --allow-http-registry \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
  "$IMAGE" | jq .
```

The verification succeeds. cosign lists the checks it made on standard error and prints a JSON list on standard output, with one item per signature it accepted; the workstation's identity URI appears in it. Treat the exact JSON layout as informational: a script should rely on the exit code of `cosign verify`, not on parsing this output. Now ask for another identity, the release bot in `ci`:

```sh
cosign verify --allow-http-registry \
  --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
  "$IMAGE"
```

This time verification fails: there is a valid signature on the image, but none of its certificates names `ci/release-bot`. That is exactly the behaviour you want. The question "is this image signed?" is meaningless; the useful question is "is this image signed by this identity?".

You can now sign an image by digest, find its signature in the registry, and verify it for one exact identity. The open question is who should sign a release: the workstation, which a person can open a shell in, is the wrong identity for that.

## Common pitfalls

> [!WARNING]
> - **Signing a tag.** The signature covers the digest the tag pointed at in that moment. Look up the digest first and sign that, so you know exactly what you signed.
> - **Reading "verified" as "trusted".** A signature from any identity verifies if you allow any identity. Always name the exact identity you expect.
> - **Expecting signing to change the image.** The image digest stays the same. The signature is a separate artifact next to it.
> - **Using `--allow-http-registry` outside a lab.** It exists for test registries without TLS. A real registry uses HTTPS.
