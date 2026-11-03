# Operate Keyless Signing

A keyless pipeline that works on the day it is built can still fail six months later: a token expires, a service is unreachable, a trusted root changes, or a signer is moved to a new namespace. This module is about the day-two work: planning the move away from keys, running both signers during a migration, keeping trust files current, and reading the failures of a signing Job.

The module has four parts. **Planning The Move From Keys To Keyless** lists what has to change and in what order. **Running Two Signers During A Migration** keeps both signatures valid until the verifiers have moved. **Reading The Failures Of A Signing Job** maps error messages to causes. **Keeping Trust Current** covers the trusted root and the signing configuration over time. A graded lab follows the last part.

## Learning objectives

After this module you can:

- List the places that use a signing key and plan their replacement in order.
- Explain why a migration signs with both methods for a time.
- Read the log of a failed signing Job and name the cause.
- Tell a token problem from a service problem from a trust problem.
- Explain what must be updated in a verifier when Fulcio or Rekor keys rotate.

## Before you start

You need to know GitHub Actions and Kubernetes CI signers, the verification flags, and the trust files.

Your playground is the same private Sigstore stack. The namespace `ci` has the service accounts `release-bot` and `ci-builder`, and the ConfigMap `release-info` records the release digest.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
