# Summary

A keyless verification checks two things in the certificate: the identity in the Subject Alternative Name and the issuer in Fulcio's issuer extension. `--certificate-identity` and `--certificate-oidc-issuer` compare them as exact strings; the `-regexp` variants take a Go regular expression. A regular expression matches anywhere in the string unless it is anchored with `^` and `$`, and an unescaped dot matches any character. A pattern such as `release-bot` therefore accepts a release bot from any namespace. When only one identity is acceptable, an exact string is simpler and cannot be too loose.

The issuer must be pinned as tightly as the identity. The Kubernetes identity URI is the same in every cluster, and many providers can issue similar identities, so only the issuer says who vouched for it. A pattern like `--certificate-oidc-issuer-regexp '.*'` passes every test in a single-issuer setup and still accepts any issuer Fulcio trusts.

GitHub Actions certificates use the issuer `https://token.actions.githubusercontent.com` and an identity that is the URL of the workflow file at its reference. Fulcio records the run's claims in separate extensions: source repository, reference, commit, trigger and the workflow that ran. An organisation-wide identity pattern accepts every repository in the organisation; `--certificate-github-workflow-repository` narrows the check to one repository, and `--certificate-github-workflow-ref` to one reference.

A Sigstore bundle and a trusted root are enough to verify offline: the bundle holds the certificate, the signature and the Rekor entry with its signed time and inclusion proof, and the trusted root holds the keys to check them. An offline verifier must keep its trusted root current, because key rotations add new keys to it. The key facts to remember are these:

- Anchor every identity regular expression, or use an exact identity.
- Always pin the issuer with its exact URL.
- For GitHub Actions, check the repository claim when one repository may ship.
- A verification script is a policy: rely on its exit code and keep it as strict as the task.

<!-- astrona:playground:destroy -->
