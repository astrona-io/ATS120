# The Fulcio Root And The Certificate Chain

A certificate is only useful if a verifier can follow it to a certificate it already trusts. This part shows the chain Fulcio returns, how to extract each certificate, and how to check the leaf certificate against the root with `openssl`.

## Leaf, intermediate and root

Fulcio answers with a **certificate chain**: the **leaf certificate** (the short-lived one for your ephemeral key), then the certificates that signed it, up to a **root certificate**. The root is the one the verifier holds in its trusted root file. A verifier accepts the leaf only if it can build a path from the leaf to a trusted root and every certificate on the path is valid at the time of signing.

<!-- astrona:playground:renew -->

Get the chain Fulcio publishes. In the workstation shell, request the trust bundle and save each certificate to its own file:

```sh
curl -s http://fulcio-server.fulcio-system.svc/api/v2/trustBundle \
  | jq -r '.chains[0].certificates[]' > /tmp/chain.pem
grep -c 'BEGIN CERTIFICATE' /tmp/chain.pem
```

The count is the number of certificates in the first chain. In the private stack the chain is short, because the scaffold chart creates one Fulcio signing certificate. The public-good instance uses a root and an intermediate certificate.

## Reading the certificates

Print the subject, issuer and validity of the certificates in the file:

```sh
openssl crl2pkcs7 -nocrl -certfile /tmp/chain.pem | openssl pkcs7 -print_certs -noout
```

Each certificate prints a `subject=` line and an `issuer=` line. For a root certificate, both are the same. Now take the leaf certificate out of a bundle and check it against that chain. Sign the release file first so the bundle exists:

```sh
cosign sign-blob --yes --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --bundle /tmp/release.sigstore.json /work/release/inventory-1.0.tar.gz
jq -r '.verificationMaterial.certificate.rawBytes // .verificationMaterial.x509CertificateChain.certificates[0].rawBytes' \
  /tmp/release.sigstore.json | base64 -d | openssl x509 -inform DER -out /tmp/leaf.pem
```

Then verify the leaf against the chain. The leaf is expired when the ten minutes pass, so use `-no_check_time` to check only the signatures:

```sh
openssl verify -no_check_time -CAfile /tmp/chain.pem /tmp/leaf.pem
```

If the chain has an intermediate, `openssl` may ask for it as an untrusted certificate with `-untrusted`; in that case split the file so the root alone is in `-CAfile`. A success message ends in `OK`.

## Why the check uses no clock

You used `-no_check_time` on purpose. The leaf lives about ten minutes, so on a later day the normal check would say the certificate has expired. A Sigstore verifier does not use the current time. It uses the integrated time from the Rekor entry, as the earlier steps of the course showed. When you write your own checks with `openssl`, you must make the same choice, or you must verify within the ten minutes.

You now know how the chain ties a short-lived certificate to a long-lived root. The open question is what extra proof sits inside the leaf certificate itself.

## Common pitfalls

> [!WARNING]
> - **Checking an old leaf with the clock.** The check fails for every old bundle. Compare with the integrated time, or limit the check to the signatures.
> - **Trusting an intermediate directly.** Put only the root in the trust file. The verifier must be able to follow the path to it.
> - **Using the wrong chain.** The private stack and the public-good instance have different roots. A bundle from one fails against the other's root.
