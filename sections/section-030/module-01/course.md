# Verify Exactly Who Signed

Three images sit in the registry, all validly signed. One was signed by the release pipeline, one by a pipeline in another namespace that happens to use the same service account name, and one from a workstation someone had a shell in. A check that only asks "is it signed by something called release-bot?" accepts two of them. Only an exact check accepts just the one that should ship.

Keyless verification has two inputs that decide everything: the **identity** in the certificate's Subject Alternative Name and the **issuer** in Fulcio's issuer extension. cosign checks both, either as exact strings or as regular expressions. This module is about choosing and writing those two values so the check accepts exactly the signer you mean.

The module has three parts. **Exact Identities, Regular Expressions And Issuers** compares what an exact identity, a loose regular expression and an anchored one accept on the three images. **GitHub Actions Identities** reads the identity and the claims in a certificate from GitHub Actions and verifies a public image. **Verifying Offline With A Bundle** verifies with only a file, its bundle and a trusted root. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Choose between `--certificate-identity` and `--certificate-identity-regexp`.
- Write an anchored regular expression that matches exactly what you mean.
- Pin the OIDC issuer, and explain why an unpinned issuer breaks the check.
- Read the identity and the GitHub claims in a GitHub Actions certificate.
- Verify a public image with `--certificate-github-workflow-repository`.
- Verify a Sigstore bundle offline with a trusted root.

## Before you start

You need to know what a keyless certificate carries: an identity URI or email in the Subject Alternative Name, and the issuer in a Fulcio extension. You also need basic regular expressions: `.`, `*`, `^` and `$`.

Your playground is a single-node `kind` cluster with a private Sigstore stack. The registry holds three images, each signed by a different identity:

| Image | Signed by |
| --- | --- |
| `registry.localtest.me:5001/inventory/podinfo:6.15.0` | `https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot` |
| `registry.localtest.me:5001/inventory/podinfo:6.15.0-rc1` | `https://kubernetes.io/namespaces/build/serviceaccounts/release-bot` |
| `registry.localtest.me:5001/inventory/podinfo:6.15.0-hotfix` | `https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation` |

You work in the `workstation` pod, which has `cosign`, `regctl`, `jq` and `openssl`, the trust files in `/etc/sigstore` and outbound internet for the public image. The first start takes up to 15 minutes.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
