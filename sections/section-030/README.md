# Section 030: Verifying Identities Precisely

A keyless signature is only as strong as the check that reads it. If the verifier accepts any identity that looks roughly right, an attacker does not need to break any cryptography: they only need an identity that matches the pattern. This section is about writing that check precisely.

You start with your own cluster's identities: exact identities, regular expressions and the issuer, and how a pattern that looks strict can accept the wrong workload. Then you move to GitHub Actions identities, the most common keyless signer on the internet, and the claims Fulcio records about the repository and workflow. Last, you verify a bundle with nothing but the file, the bundle and a trusted root.

**Topic covered:** Verification

## What you will learn

- The difference between `--certificate-identity` and `--certificate-identity-regexp`, and how to anchor a regular expression.
- Why the issuer must be pinned as tightly as the identity.
- The identity and claims in a GitHub Actions certificate, and the flags that check them.
- Verifying a public image that was signed in GitHub Actions.
- Verifying a bundle offline with a trusted root.

## The learning path

The module starts at its landing page, which also launches the playground. The playground has the private Sigstore stack and three images, each signed by a different identity, so you can compare what different checks accept.

### 1. Verify Exactly Who Signed

1. Exact Identities, Regular Expressions And Issuers
2. GitHub Actions Identities
3. Verifying Offline With A Bundle, followed by the lab **Tighten A Verification Script**
4. Summary

## Section capstone: Verify Which Repository Built A Public Image

The capstone is one graded scenario that combines the module. You write a check for a public image signed in GitHub Actions that accepts exactly one repository, where the obvious organisation-wide check accepts its neighbours too. The capstone needs outbound internet. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-120-capstone-030
```
