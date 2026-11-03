# Section 040: Keyless Signing In CI

The place that most needs keyless signing is the pipeline. A long-lived signing key in a CI secret is readable by every workflow change and every compromised dependency that runs in that pipeline. Keyless signing replaces it with the pipeline's own identity, handed to the job by the platform for one run.

This section covers both pipelines you are likely to meet. In GitHub Actions, a workflow job asks GitHub for an ID token and signs with it. In Kubernetes, a Job signs with its own projected service account token. The pattern is the same in both: sign the digest the build produced, verify it in the same run with the exact identity, and keep no key anywhere.

**Topic covered:** CI

## What you will learn

- The `id-token: write` permission and how a GitHub Actions job gets an ID token.
- A complete keyless signing workflow for GitHub Actions, and the identity it produces.
- Building a Kubernetes Job that signs the release digest and verifies it in the same run.
- Moving a pipeline from a signing key in a Secret to keyless signing.
- Protecting the signing step and verifying a CI signature at deploy time.
- Other CI providers and issuers: how Fulcio trusts an issuer, GitLab CI identities, and the flags for each provider.
- Operating keyless signing: migration, reading signing failures and keeping trust files current.

## The learning path

Each module starts at its landing page, which also launches that module's playground. The playground has the private Sigstore stack, the registry with the release image, the namespace `ci` with the service account `ci-builder`, and the ConfigMap `release-info` with the release digest.

### 1. Sign In CI Without A Stored Key

1. Keyless Signing In GitHub Actions
2. A Kubernetes Job As The CI Signer, followed by the lab **Sign And Verify In A CI Job**
3. Protecting The Signing Step
4. Verifying A CI Signature At Deploy
5. Summary

### 2. Other CI Providers And Issuers

1. How Fulcio Decides Which Issuers To Trust
2. GitLab CI Identities
3. Reading The Issuer And Subject Of Any Signature
4. Choosing The Flags For Each Provider, followed by the lab **Configure A Verifier For A Provider**
5. Summary

### 3. Operate Keyless Signing

1. Planning The Move From Keys To Keyless
2. Running Two Signers During A Migration
3. Reading The Failures Of A Signing Job
4. Keeping Trust Current, followed by the lab **Find Why Three Signers Failed**
5. Summary

## Section capstone: Move A Pipeline From A Signing Key To Keyless

The capstone is one graded migration. The pipeline signs with a key pair kept in a Secret, and the deployment check verifies with the matching public key. You replace the signer, remove the key and move the check to a pinned identity. Work it after the module labs.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-120-capstone-040
```
