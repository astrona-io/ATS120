# Trust Roots And Signing Configuration

A signature is only as trustworthy as the keys the verifier uses to check it. A signer must also know which services to call. Sigstore keeps both answers in two JSON files: the trusted root for verifiers and the signing configuration for signers. If you can read these files, you can explain almost every "cannot verify" and "cannot sign" error.

The module has four parts. **What The Trusted Root Contains** reads `trusted-root.json` field by field. **What The Signing Configuration Contains** reads `signing-config.json`. **Validity Windows And Key Rotation** explains why every key has a time range. **How The Public-Good Instance Distributes Trust** explains The Update Framework (TUF), which delivers both files on the public internet. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Name the four lists in a trusted root and what each one verifies.
- Name the service lists in a signing configuration and what a signer does with each.
- Use `jq` to find why a verification fails because of a trust file.
- Explain validity windows and why old signatures still verify after a key rotation.
- Explain how TUF protects the delivery of the trusted root.

## Before you start

You need to know the keyless flow and be able to use `jq` and `kubectl exec`. Your playground has the private stack, and the workstation holds both files in `/etc/sigstore`. The ConfigMap `sigstore-trust` in `workstation` holds the same files, which the bootstrap built with `cosign trusted-root create` and `cosign signing-config create`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
