# Section 010: How Keyless Signing Works

A signing key that lives for years is a liability. Someone has to store it, protect it, rotate it and revoke it when it leaks, and every verifier has to know which public key belongs to whom. Keyless signing removes that key. It signs with a key pair that exists for one signature only, and it binds that key to an identity with a certificate that is valid for about ten minutes.

This section takes the keyless flow apart in the order it happens. First the identity: an OpenID Connect (OIDC) identity token, the signed statement of who is signing. Then the certificate: what Fulcio, the Sigstore certificate authority, checks in the token and what it writes into the certificate. Last the record: the certificate transparency log entry and the Rekor entry that keep the signature verifiable after the certificate has expired.

**Topic covered:** Keyless flow

## What you will learn

- Why long-lived signing keys are hard to manage, and what keyless signing does instead.
- The parts of the keyless flow and which Sigstore service does each step.
- Reading the claims of an OIDC identity token: `iss`, `sub`, `aud`, `exp`.
- What Fulcio checks before it issues a certificate, and what it writes into the certificate.
- Why a ten-minute certificate still verifies a year later: the transparency log.
- Signing a file keylessly and verifying its Sigstore bundle.

## The learning path

The module starts at its landing page, which also launches the playground. The playground has a private Sigstore stack, an image registry and the `workstation` pod with the client tools and a token for its own identity.

### 1. Sign Without A Long-Lived Key

1. From Long-Lived Keys To Short-Lived Certificates
2. Reading An OIDC Identity Token
3. What Fulcio Puts In A Certificate, followed by the lab **Sign A Release File Keylessly And Publish Its Bundle**
4. Summary

## Section capstone: Repair A Keyless Signing Setup

The capstone is one graded scenario that combines the whole module. The workstation can no longer sign keylessly, and the release bundle someone published was made with a long-lived key. Three faults stand between you and a keyless bundle that verifies. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-120-capstone-010
```
