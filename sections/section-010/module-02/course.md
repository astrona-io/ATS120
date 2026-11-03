# Follow One Certificate Request

Section one showed the keyless flow as a picture. This module opens each step. You will see what cosign sends to Fulcio, what Fulcio answers, how the certificate chain is built, what the certificate transparency log adds, and what a Rekor entry contains. Each step is something you can inspect in your playground, so you can check a signature without trusting any tool's word for it.

The module has four parts. **The Request Fulcio Receives** covers the Fulcio API, the proof of possession and the checks Fulcio makes. **The Fulcio Root And The Certificate Chain** shows how a certificate is checked against the root. **Certificate Transparency And The SCT** explains the signed certificate timestamp. **Reading A Rekor Entry** looks up a log entry and its proofs. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Name the Fulcio API calls cosign makes and what each one carries.
- Explain what the proof of possession proves and what it does not.
- Check a Fulcio certificate against the Fulcio root with `openssl`.
- Find the signed certificate timestamp (SCT) in a certificate.
- Look up a Rekor entry by log index and by artifact hash, and read its fields.
- Explain what an inclusion proof and a signed entry timestamp prove.

## Before you start

You need to know the keyless flow (ephemeral key, OIDC token, Fulcio certificate, Rekor entry) and be able to run commands in the `workstation` pod with `kubectl exec`.

Your playground is the same private Sigstore stack as before. The workstation holds the release file `/work/release/inventory-1.0.tar.gz`, a projected token in `/var/run/sigstore/token` and the trust files in `/etc/sigstore`. The services are reached inside the cluster at `fulcio-server.fulcio-system.svc` and `rekor-server.rekor-system.svc`, both on port 80.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
