# Enforcing Signers And Claims In A Cluster

Checks in a script run when someone remembers to run them. A cluster can run them for every pod at admission, so an image that fails does not start. This part describes how the sigstore policy controller expresses the checks you have written by hand, without installing it.

## What the policy controller does

The sigstore policy controller is an admission webhook. When a pod is created, it looks at the images in the pod spec and checks them against policies. A policy is a custom resource called `ClusterImagePolicy`. Namespaces opt in with a label, and a pod whose image has no matching policy that passes is rejected.

## What a policy contains

A `ClusterImagePolicy` has two main parts:

- **images**, a list of glob patterns for the images the policy applies to, for example everything in one repository.
- **authorities**, the ways an image can pass. A keyless authority names a Fulcio, a Rekor and a trusted root, and a list of identities. Each identity pairs an issuer with a subject, either as an exact string or as a regular expression.

These are the same inputs as `--certificate-oidc-issuer` and `--certificate-identity` in `cosign verify`. Everything you learned about exact identities and anchoring applies unchanged: a policy with a loose subject expression admits what the loose command would accept.

## Requiring a claim

An authority can also require an attestation of a given type. The policy then rejects the image unless a matching attestation exists, signed by the listed identity. The predicate can be checked with a CUE or Rego policy, which is the same kind of rule as the `--policy` flag of `cosign verify-attestation`. With this, a rule such as "no critical findings, attested by the scanner identity" runs on every admission.

## Where this fits

| Check | Where it runs | What it protects |
| --- | --- | --- |
| `cosign verify` in a script | In the pipeline | The step that runs it |
| Verification in a deploy tool | At rollout | The rollout |
| Admission policy | At pod creation | Every way a pod can start |

Admission is the last place a bad image can be stopped, because it applies to pods created by hand, by a controller or by a restarted node. A script in the pipeline can be skipped; an admission webhook cannot, as long as its namespaces are labelled and the webhook is available.

## Common pitfalls

> [!WARNING]
> - **Policies with `fail open` behavior.** Decide what happens when the webhook cannot answer. A webhook that is down and allows everything is no gate.
> - **Unlabelled namespaces.** A namespace without the opt-in label is not checked at all.
> - **A policy that names a tag.** Policies and checks need digests, as everywhere in this course.

## Your mission: Read And Check An Attestation

You can now create, verify and read attestations. The graded lab gives you an image that carries an attestation from the workstation identity and asks you to verify it, read its content and record what it says.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-120-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-120-lab-030-02
astrona start ats-120-playground-030-02
```
