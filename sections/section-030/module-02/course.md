# Verify Claims About An Image, Not Only Its Signer

A signature says who vouches for a digest. It does not say what they vouch for. An **attestation** is a signed statement about a digest: that a scanner found no critical vulnerabilities, that a build ran on a given commit, that a review approved the release. A verifier can then ask two questions: who signed the statement, and what does the statement say?

This module shows how to create an attestation keylessly, how to verify it with the same identity and issuer checks as a signature, how to read and check its content, and how a cluster can enforce both at admission.

The module has four parts. **What An Attestation Is** takes apart the statement and its envelope. **Creating An Attestation Keylessly** signs a statement about the release image. **Verifying An Attestation And Its Content** checks the signer and then the predicate. **Enforcing Signers And Claims In A Cluster** describes admission policy. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Name the parts of an in-toto statement: subject, predicate type and predicate.
- Explain what the DSSE envelope adds and what it does not.
- Create a keyless attestation with `cosign attest`.
- Verify one with `cosign verify-attestation` and read its predicate.
- Check the content of a predicate, not only the identity of its signer.
- Explain how the sigstore policy controller expresses the same checks as policy.

## Before you start

You need to know the keyless flow, workload identity signing and exact identity checks. You also need `jq` and the idea of base64 encoding.

Your playground is the same private Sigstore stack. The registry has the image `inventory/podinfo:6.15.0`. The workstation can sign with its own identity, and the namespace `ci` has the service account `release-bot`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
