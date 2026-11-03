# Validity Windows And Key Rotation

Keys do not live forever. A certificate authority replaces its signing key, and a log replaces its log key. Signatures made years ago must still verify. This part explains how the `validFor` ranges make both possible.

## One range per key

Every anchor in a trusted root has a `validFor` range with a `start` time and an optional `end` time. A range with no `end` means the key is still in use. When an operator rotates a key, it adds the new key with a new `start` and sets an `end` on the old key. The old key stays in the file.

A verifier chooses the anchor by the signing time. For a Fulcio certificate and a Rekor entry, that time is the integrated time of the log entry. The verifier looks for an anchor whose range contains the integrated time. A signature made while the old key was current verifies with the old entry, even after the new key is in use.

<!-- astrona:playground:renew -->

Print the ranges in your playground. Open a shell in the workstation:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
jq '[.tlogs[], .ctlogs[]] | map({baseUrl, validFor: .publicKey.validFor})' /etc/sigstore/trusted-root.json
jq '.certificateAuthorities | map({uri, validFor})' /etc/sigstore/trusted-root.json
```

Each range has a `start` and no `end`, because the private stack has never rotated a key.

## Breaking a range on purpose

Copy the file and give the Rekor key an `end` time in the past. Then verify a bundle with the copy. First create a bundle with the current files:

```sh
cosign sign-blob --yes --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --bundle /tmp/release.sigstore.json /work/release/inventory-1.0.tar.gz
jq '.tlogs[0].publicKey.validFor.end = "2020-01-01T00:00:00Z"' /etc/sigstore/trusted-root.json > /tmp/expired-root.json
```

Now verify with the changed root:

```sh
cosign verify-blob --bundle /tmp/release.sigstore.json \
  --trusted-root /tmp/expired-root.json \
  --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
  /work/release/inventory-1.0.tar.gz
```

The verification fails, because no Rekor key is valid at the integrated time of the entry. Run the same command with `/etc/sigstore/trusted-root.json` and it succeeds. The file, and not the signature, was the problem.

## What rotation means for you

When an operator rotates a key, verifiers must receive the new trusted root before signers use the new key. A verifier with an old file fails on new signatures. A verifier with a new file still verifies old signatures. This is why the file must be delivered with care, which is the topic of the next part.

## Common pitfalls

> [!WARNING]
> - **Deleting old anchors after a rotation.** Old signatures stop verifying.
> - **Reading "key expired" as "signature invalid".** The key may be outside the range of the integrated time only because the file is wrong or old.
> - **Keeping an old trusted root on a verifier.** New signatures fail until the file is replaced.
