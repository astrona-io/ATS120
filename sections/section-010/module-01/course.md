# Sign Without A Long-Lived Key

A team signs its releases with a key pair it created three years ago. The private key sits in a CI secret, and nobody remembers who else has a copy. If the key leaks, every signature it ever made becomes worthless, and every verifier must be told to trust a new public key. Keyless signing avoids that whole problem by never keeping a signing key at all.

**Keyless signing** signs with an **ephemeral key**: a key pair that cosign, the Sigstore command-line tool, creates for one signature and then throws away. To make that key mean something, Fulcio, the Sigstore certificate authority, issues a certificate that binds the key to an identity. Fulcio learns the identity from an **OpenID Connect (OIDC) identity token**, a signed statement from an identity provider that says who the signer is.

This module follows one keyless signature from start to end. **From Long-Lived Keys To Short-Lived Certificates** explains the flow and the services that take part. **Reading An OIDC Identity Token** opens the token your workstation uses and reads its claims. **What Fulcio Puts In A Certificate** signs a file, opens the certificate, and explains why the signature stays valid after the certificate expires. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain the problems of long-lived signing keys and how keyless signing avoids them.
- Name the services in the keyless flow and what each one does: the OIDC provider, Fulcio, the certificate transparency log and Rekor.
- Decode an OIDC identity token and read its `iss`, `sub`, `aud` and `exp` claims.
- Explain what Fulcio checks before it issues a certificate.
- Read the identity and the issuer in a Fulcio certificate.
- Explain why the transparency log keeps a signature verifiable after the certificate expires.
- Sign a file keylessly, publish its Sigstore bundle and verify it.

## Before you start

You need Kubernetes basics: namespaces, pods, service accounts, ConfigMaps and the commands `kubectl get`, `kubectl apply` and `kubectl exec`. You also need to know what a public key and a certificate are for. This module does not teach public-key cryptography; it teaches how Sigstore uses it.

Your playground is a single-node `kind` cluster with a private Sigstore stack: Fulcio, Rekor and a certificate transparency log, installed with the `scaffold` Helm chart. Fulcio trusts this cluster's own service account tokens. You work in the `workstation` pod, which runs as the service account `workstation` in the namespace `workstation`:

| Path in the workstation | What it is |
| --- | --- |
| `/var/run/sigstore/token` | A projected service account token with the audience `sigstore`, renewed by the kubelet |
| `/etc/sigstore/trusted-root.json` | The certificates and keys of this private stack that a verifier trusts |
| `/etc/sigstore/signing-config.json` | The Fulcio and Rekor addresses cosign uses when it signs |
| `/etc/sigstore/oidc-issuer` | The issuer URL of this cluster's service account tokens |
| `/work/release/inventory-1.0.tar.gz` | A release file to sign |

The pod has `cosign` v3.1.4, `rekor-cli`, `regctl`, `jq` and `openssl`. Every command in the parts runs against the playground cluster, and `kubectl` already points at it. The first start takes up to 15 minutes, because the whole Sigstore stack starts with it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
