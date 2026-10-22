# Sign In CI Without A Stored Key

The release pipeline signs every image with a key pair. The private key and its password live in two CI secrets. Every person who can change a workflow file can print them, and so can any build step that runs third-party code. Rotating the key means updating every verifier. Keyless signing in CI removes the key: the platform gives the job a short-lived identity token for each run, and Fulcio turns it into a ten-minute certificate.

Two kinds of pipeline matter here. In **GitHub Actions**, the job asks GitHub's OpenID Connect (OIDC) provider for an ID token; that works without any stored secret once the workflow has the permission `id-token: write`. In **Kubernetes**, a Job gets a projected service account token for its own service account. Both are **ambient credentials**: the platform provides them, nobody stores them.

The module has two parts. **Keyless Signing In GitHub Actions** walks through a complete signing workflow and the identity it produces; a lab cannot run GitHub, so this part explains it with the real workflow file. **A Kubernetes Job As The CI Signer** builds the same pattern in the cluster: sign the digest, verify it in the same run, no Secret. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain how a GitHub Actions job gets an ID token and what `id-token: write` allows.
- Write a GitHub Actions workflow that signs an image by digest keylessly.
- Name the identity and the issuer a GitHub Actions signature carries.
- Build a Kubernetes Job that signs the release digest as its own service account.
- Verify the signature in the same Job with the exact identity.
- Keep every key and Secret out of a signing pipeline.

## Before you start

You need Kubernetes Jobs, init containers, service accounts and ConfigMaps, and a basic idea of a GitHub Actions workflow file: jobs, steps and `uses:`. You also need to know that a keyless certificate names an identity and an issuer, and that `cosign verify` must be told both.

Your playground is a single-node `kind` cluster with a private Sigstore stack, the registry at `registry.localtest.me:5001` with `inventory/podinfo:6.15.0`, and the `workstation` pod. The namespace `ci` has:

| Object | What it is |
| --- | --- |
| Service account `ci-builder` | The identity of the CI signer |
| ConfigMap `release-info` | Key `image`: the release image by digest |
| ConfigMap `sigstore-trust` | `trusted-root.json`, `signing-config.json` and `oidc-issuer` |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it. The first start takes up to 15 minutes.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
