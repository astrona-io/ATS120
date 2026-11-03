# Keeping Trust Current

Keyless verification trusts two files: the trusted root and, for signing, the signing configuration. They change over time. A verifier that never updates them will one day reject a good signature, or accept one it should not. This part explains what changes and what to do about it.

## What changes

The trusted root holds the keys of the certificate authority, the transparency log and the certificate transparency log, each with a validity window. When an operator rotates a key, the new key gets a window, and the old one gets an end. Signatures made in the old window stay valid because the check uses the integrated time, but a verifier needs both keys to verify both old and new signatures.

The signing configuration holds the service URLs. When the services move, signers need the new file.

## How the files reach consumers

| Instance | Distribution |
| --- | --- |
| Public-good | The trusted root is distributed through TUF. cosign fetches and verifies updates |
| Private | The operator publishes the files, in this course through the ConfigMap `sigstore-trust` |

For a private instance, the update is a procedure you own. Write it down and test it before rotation day.

## A routine

- Compare the verifier's copy with the operator's copy on a schedule. In the playground, compare the files in `sigstore-trust` of two namespaces with `diff`.
- Keep old keys in the file until no signature needs them.
- After an update, verify a signature from before the change and one from after.
- Alert on a verification failure that mentions an unknown key.

<!-- astrona:playground:renew -->

Compare two copies of the trusted root in the playground:

```sh
kubectl -n workstation get configmap sigstore-trust -o jsonpath='{.data.trusted-root\.json}' | sha256sum
kubectl -n ci get configmap sigstore-trust -o jsonpath='{.data.trusted-root\.json}' | sha256sum
```

If the two hashes differ, one namespace has an older file.

## Common pitfalls

> [!WARNING]
> - **Removing the old key at rotation.** Old signatures stop verifying.
> - **Updating signers but not verifiers.** Signing works and verification fails.
> - **Copying the trusted root by hand once.** Without a routine the copy goes stale.

## Your mission: Find Why Three Signers Failed

You can now read the failure of a signing Job and keep the trust files current. The graded lab gives you three signing Jobs that failed for three different reasons and asks you to name each reason.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-120-playground-040-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-040/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-120-lab-040-03
astrona start ats-120-playground-040-03
```
