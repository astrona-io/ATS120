# Reading The Issuer And Subject Of Any Signature

Sometimes you meet an image or a bundle and need to know who signed it, before you can write a strict check. This part shows how to discover the identity and issuer, then turn the discovery into a pin. The discovery step is for reading only. It must never be the check.

## Discover with a permissive command

`cosign verify` needs an identity and an issuer. To discover them, give regular expressions that match everything, and read the answer. Run this from the workstation against the release image, after something has signed it:

<!-- astrona:playground:renew -->

```sh
IMAGE=registry.localtest.me:5001/inventory/podinfo
cosign verify --allow-http-registry --trusted-root /etc/sigstore/trusted-root.json \
  --certificate-identity-regexp '.*' --certificate-oidc-issuer-regexp '.*' \
  $IMAGE@$(regctl image digest $IMAGE:6.15.0) | jq '.[].optional | keys'
```

The command verifies the signature against the trusted root and the log but accepts any signer. It prints the keys of the certificate details. Print the subject and issuer fields among them. The exact key names depend on the cosign version, so list the keys first, as above.

## Discover from a bundle

For a blob with a Sigstore bundle, read the certificate directly. This works offline and does not need the signed file:

```sh
jq -r '.verificationMaterial.certificate.rawBytes // .verificationMaterial.x509CertificateChain.certificates[0].rawBytes' bundle.json \
  | base64 -d | openssl x509 -inform DER -noout -ext subjectAltName
```

The `URI:` line is the identity. The issuer is in the Fulcio extension with the object ID `1.3.6.1.4.1.57264.1.8` (the newer form) or `1.3.6.1.4.1.57264.1.1` (the older form). Print the certificate with `openssl x509 -text -noout` and look for them.

## Turn the discovery into a pin

Once you know the values, check them against what you expect. If the identity belongs to the pipeline you meant, put it into the check as an exact string, together with the issuer. Then run the exact check and confirm that it passes, and that a different identity fails.

The permissive command stays out of scripts. A script that uses `.*` for both values checks only that some signature exists, which any attacker with a Fulcio token can produce.

## Common pitfalls

> [!WARNING]
> - **Leaving the discovery command in the pipeline.** Search for `'.*'` in your verification scripts and remove it.
> - **Pinning what you found without asking whether it is right.** The discovery tells you who signed. It does not tell you that they were allowed to.
> - **Confusing the two issuer OIDs.** Fulcio writes both for compatibility; read the newer one when present.
