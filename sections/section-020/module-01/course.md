# Sign As A Kubernetes Workload

A cluster runs many jobs: builds, tests, releases, nightly scans. If any of them can produce a signature that looks like a release signature, the signature means nothing. What a verifier needs is a signature that names the exact workload that made it, and a way to make that workload the only one able to produce it.

A Kubernetes **service account** is the identity of a pod inside the cluster. With keyless signing, the pod's projected service account token becomes the identity in the certificate. So the rule is simple: give every signer its own service account, and its signatures carry their own identity.

The module has two parts. **Signing An Image With A Service Account Token** signs an image from the workstation, shows where cosign stores the signature, and verifies it. **Running The Signer As Its Own Workload** moves the signing into a Job that runs as the service account `release-bot` and keeps no key anywhere. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Sign a container image keylessly with a projected service account token.
- Explain why cosign signs an image digest and not a tag.
- Find the signature cosign attached to an image in the registry.
- Name the identity Fulcio writes for a service account.
- Write a Job that signs as its own service account with no Secret.
- Verify an image for one exact workload identity and see other identities fail.

## Before you start

You need Kubernetes basics: namespaces, pods, Jobs, service accounts and ConfigMaps, and the commands `kubectl apply`, `kubectl logs` and `kubectl exec`. You also need to know that an image has a tag, which can move, and a digest, which identifies the exact content.

Your playground is a single-node `kind` cluster with a private Sigstore stack: Fulcio, Rekor and a certificate transparency log. Fulcio trusts this cluster's service account tokens with the audience `sigstore`. The objects you work with are these:

| Object | What it is |
| --- | --- |
| `registry.localtest.me:5001/inventory/podinfo:6.15.0` | The example image in the in-cluster registry (plain HTTP, lab-only) |
| `workstation` (namespace `workstation`) | The pod with `cosign`, `regctl`, `jq`, a projected token and the trust files in `/etc/sigstore` |
| ConfigMap `release-info` (namespace `ci`) | Key `image`: the release image by digest |
| ConfigMap `sigstore-trust` (namespaces `workstation` and `ci`) | `trusted-root.json`, `signing-config.json` and `oidc-issuer` |
| Service account `release-bot` (namespace `ci`) | The identity the release signer should run as |

Every command in the parts runs against the playground cluster, and `kubectl` already points at it. The first start takes up to 15 minutes.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
