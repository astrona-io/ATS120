# Section 020: Signing With A Workload Identity

A signature is useful when it says which workload made it. If every job in a cluster signs with the same key, or as the same identity, a verifier cannot tell the release pipeline from a test job. Keyless signing with workload identities fixes that: each workload signs with its own token, and Fulcio writes that workload's identity into the certificate.

This section signs container images with Kubernetes service account tokens. First you sign from the workstation and read the identity Fulcio wrote. Then you move the signing into its own Job, running as its own service account, so the signature names the job that made it.

**Topic covered:** Workload identity

## What you will learn

- Signing an image keylessly with a projected service account token.
- Where cosign stores an image signature, and why it signs the digest, not the tag.
- The identity Fulcio writes for a Kubernetes service account.
- Running a signing Job as a dedicated service account, with no stored key.
- Verifying an image for one exact workload identity.

## The learning path

The module starts at its landing page, which also launches the playground. The playground has the private Sigstore stack, the registry with `inventory/podinfo:6.15.0`, the `workstation` pod, and the namespace `ci` with the service account `release-bot`.

### 1. Sign As A Kubernetes Workload

1. Signing An Image With A Service Account Token
2. Running The Signer As Its Own Workload, followed by the lab **Sign As The Release Bot**
3. Summary

## Section capstone: Sign Two Images With Their Own Identities

The capstone is one graded scenario that combines the module. Two signing Jobs are supposed to sign two images, each as its own service account. One of them signed as the wrong identity, and the other failed. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-120-capstone-020
```
