# Summary

Fulcio trusts a list of OIDC issuers. Each entry has an issuer URL, a client ID that must appear as the audience, and a type that decides how the token's claims become the certificate subject and extensions. Fulcio v1.9.0 supports the types email, username, uri, spiffe, kubernetes, github-workflow, gitlab-pipeline, codefresh-workflow, buildkite-job, chainguard-identity and ci-provider. A token from an unlisted issuer never becomes a certificate. The list is available from the endpoint `/api/v2/configuration`.

A GitLab CI job requests a token with `id_tokens` and the audience `sigstore`; cosign reads it from `SIGSTORE_ID_TOKEN`. The identity has the form `https://gitlab.com/GROUP/PROJECT//.gitlab-ci.yml@REF` and the issuer is `https://gitlab.com`. For an unknown signature, discover the identity and issuer with a permissive command or from the certificate in a bundle, then pin both exactly and never leave the permissive command in a script.

A new provider needs its issuer listed in the Fulcio you use, one test signature, discovery, an exact pin and a negative test. The key facts to remember are these:

- The issuer list is Fulcio configuration; a verifier pins the issuer too.
- The type sets the identity format for each provider.
- Discovery is for reading; a check must be exact.
- Test that a different identity fails.

<!-- astrona:playground:destroy -->
