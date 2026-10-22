# Welcome To The Course

This course trains you for the **Keyless Signing With Fulcio & OIDC** part of the Astrona **Sigstore** training path. That part is 25% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, pods, Jobs, service accounts, ConfigMaps, `kubectl apply` and `kubectl exec`. You know what a container image, a tag and a digest are. You have seen a public key and an X.509 certificate before, even if you have never built one. You do not need to know Sigstore yet. Each new idea is explained the first time it appears.

## What you can do at the end

Keyless signing replaces a long-lived signing key with a short-lived certificate for an identity. So this course does not ask you to remember words. It asks you to sign, look at what was signed and by whom, and verify that exact identity. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **how keyless signing works**. You will learn to:

- Explain the keyless flow: ephemeral key, OpenID Connect (OIDC) identity token, short-lived certificate, transparency log.
- Read the claims of an identity token and the identity Fulcio writes into a certificate.
- Sign a file keylessly and verify its Sigstore bundle.

Every signature names an identity, so the second topic is **signing with a workload identity**. You will learn to:

- Sign an image with a Kubernetes service account token.
- Run the signer as its own workload, so the signature names the job that made it.

A signature is only as strong as the check that reads it, so the third topic is **verifying identities precisely**. You will learn to:

- Verify with an exact identity and issuer, and spot regular expressions that accept too much.
- Read the GitHub Actions claims in a certificate and verify which repository built a public image.
- Verify a bundle offline with a trusted root.

The fourth topic is **keyless signing in CI**. You will learn to:

- Sign keylessly in GitHub Actions with ambient credentials.
- Build a Kubernetes Job that signs and verifies a release without any stored key.
- Move a pipeline from a long-lived key to keyless signing.

Everything is written for **cosign v3.1.4**.

## The words this course uses

The pages use Sigstore's, OIDC's and Kubernetes' own terms, because those are the words you meet in the tools, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

**Keyless signing** means signing with a key pair that exists for one signature only, and binding it to an identity with a short-lived certificate. **Fulcio** is the certificate authority that issues that certificate after it checks an **ID token**, a signed JSON Web Token (JWT) that says who you are. **Rekor** is the transparency log: an append-only record of every signature. **cosign** is the command-line tool that does the signing and the verifying.

Two files tell cosign which services to trust and use:

| File | What it holds |
| --- | --- |
| `trusted-root.json` | The certificates and keys a verifier trusts: Fulcio's root, Rekor's key, the CT log's key |
| `signing-config.json` | The Fulcio and Rekor addresses a signer uses |

## The example setup in your playground

Every playground and lab runs a private Sigstore stack inside a small Kubernetes cluster: Fulcio, Rekor and a certificate transparency log. Fulcio trusts the cluster's own service account tokens, so a pod can sign keylessly with no browser and no stored key. An image registry holds the example image `inventory/podinfo:6.15.0`.

You work in the `workstation` pod, which has `cosign`, `regctl`, `jq` and `openssl`, the two trust files and a token for its own identity. Signing jobs run in the namespace `ci` as their own service accounts, such as `release-bot`. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It follows one signature from start to end: how it is made, which identity it names, how a verifier checks that identity, and how a pipeline makes it without a key.

| Section | What it covers |
| --- | --- |
| 010 | How Keyless Signing Works |
| 020 | Signing With A Workload Identity |
| 030 | Verifying Identities Precisely |
| 040 | Keyless Signing In CI |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
