# Running Two Signers During A Migration

During the migration an image carries two signatures: one made with a key and one made keyless. Verifiers can then move one at a time. This part shows how both exist on one digest and how a verifier takes the keyless one.

## Two signatures on one digest

Signing does not change the image, so a second signature does not affect the first. The digest in the playground can carry a key-based signature and a keyless signature side by side. Create a key pair in the workstation, sign the release image with it, and then sign it keyless:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Then, inside the shell:

```sh
cd /tmp
export COSIGN_PASSWORD=""
cosign generate-key-pair
IMAGE=registry.localtest.me:5001/inventory/podinfo
DIGEST=$(regctl image digest $IMAGE:6.15.0)
cosign sign --yes --allow-http-registry --key cosign.key \
  --signing-config /etc/sigstore/signing-config.json --trusted-root /etc/sigstore/trusted-root.json \
  $IMAGE@$DIGEST
cosign sign --yes --allow-http-registry --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json --trusted-root /etc/sigstore/trusted-root.json \
  $IMAGE@$DIGEST
```

An empty password is fine for this exercise only, and the key is not kept anywhere beyond the playground. Real keys need a password or a key management system.

## Each verifier takes its own signature

Verify with the key and with the identity. Both succeed:

```sh
cosign verify --allow-http-registry --key cosign.pub --trusted-root /etc/sigstore/trusted-root.json \
  $IMAGE@$DIGEST >/dev/null && echo "key ok"
cosign verify --allow-http-registry --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" $IMAGE@$DIGEST >/dev/null && echo "keyless ok"
```

The key-based command checks the signature against the public key. It says nothing about who holds the key, only that the holder of the private key signed. The keyless command names an identity and an issuer.

A verifier that has moved needs only the second command. An old verifier that was not moved still needs the first. When no verifier uses the key, stop signing with it.

## Proving the move is finished

How do you know no verifier still depends on the key? Switch the signer first in a test environment, and watch for failures. Look at the logs of admission policies and deploy steps for key-based rejections. If there is no way to see which verifiers exist, announce the removal date and remove the key on that date. The cost of an unknown verifier breaking is smaller than the cost of a key that stays.

## Common pitfalls

> [!WARNING]
> - **Keeping the public key in a verifier after it has moved.** Remove the key from the verifier, or it still accepts the key's signature.
> - **Treating "both verify" as the end.** The aim is to remove the key.
> - **Keeping the key in the playground steps.** The key in this exercise belongs to the exercise.
