# Summary

A key is used in the signing job, the verifiers, admission policies, documentation and backups. A safe migration adds the keyless signer, signs with both methods, moves the verifiers one at a time to pinned identity and issuer, stops signing with the key, and then deletes the key everywhere. Deleting the key first breaks verifiers that still depend on it; leaving it keeps the risk.

A signing Job fails for a small set of reasons. If no pod exists, the Job's events say why, for example a missing service account. If a pod ran, the first error in the log names the cause: a refused token (audience or issuer), a missing image manifest, a registry authorization error, an unreachable service, or a trusted root that does not know a key. Do not use insecure flags to make a Job pass; fix the cause and create the Job again.

The trusted root and the signing configuration change over time. Keep old keys until no signature needs them, update verifiers as well as signers, and check a signature from before and after each rotation. The key facts to remember are these:

- Delete the key last, not first.
- A Job without a pod failed on the identity side; read its events.
- The first error in the log is the cause.
- Keep trust files current with a routine.

<!-- astrona:playground:destroy -->
