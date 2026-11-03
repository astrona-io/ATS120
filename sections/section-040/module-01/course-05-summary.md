# Summary

A signing key in a CI secret is readable by every workflow change and every build step that runs in that pipeline, and rotating it means updating every verifier. Keyless signing in CI replaces the key with the pipeline's own identity, which the platform hands the job for one run as an ambient credential.

In GitHub Actions, the job needs the permission `id-token: write` to request an ID token from GitHub's OpenID Connect provider, `https://token.actions.githubusercontent.com`. Grant it only to the job that signs. cosign fetches the token itself and signs keylessly with the public-good Sigstore instance when no key and no signing configuration are given. The certificate's identity is the URL of the workflow file at its git reference, and Fulcio records the repository, the reference, the commit and the trigger in extensions. Consumers verify with the issuer pinned and the repository, and often the trigger or reference, checked. Sign the digest the build step reported, never a tag.

In Kubernetes, a Job signs as its own service account with a projected token for the audience `sigstore`. A release Job should sign in one step and verify in the next, with the exact identity the deployment check uses, so a wrong service account or digest stops the pipeline. Only the signing step needs the token; the verify step needs the trusted root and the issuer. The key facts to remember are these:

- No key, no Secret, no password in a keyless pipeline; the token is the only credential and it expires in minutes.
- Sign the digest from one recorded source, and verify that same digest.
- Verify in the same run with the identity the deployment demands.
- When moving from a key to keyless, remove the old key once the keyless signer works.

<!-- astrona:playground:destroy -->
