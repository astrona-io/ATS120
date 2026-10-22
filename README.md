# ATS120 — Keyless Signing With Fulcio & OIDC (Sigstore)

Course material for the **Keyless Signing With Fulcio & OIDC** domain of the
Astrona Sigstore training path ([ATP023](https://github.com/astrona-io/ATP023)),
which is **25% of the path**. Written for **cosign v3.1.4** and a private
Sigstore stack (Fulcio v1.9.0, Rekor v1.5.4, a CT log) installed in the lab
cluster with the `scaffold` Helm chart 0.6.117.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Sigstore documentation and the Fulcio and cosign sources. None has
> been started on a cluster, and no lab has passed `astrona test` yet. See
> `CLAUDE.md`, which names the biggest open risk.

The course opens with an Introduction in `sections/intro/`. Each section
contains a module (landing page, parts, summary), a playground, a graded lab
right after the part it tests, and a capstone.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | How Keyless Signing Works | 1 | 1 + capstone | Keyless flow |
| [020](sections/section-020) | Signing With A Workload Identity | 1 | 1 + capstone | Workload identity |
| [030](sections/section-030) | Verifying Identities Precisely | 1 | 1 + capstone | Verification |
| [040](sections/section-040) | Keyless Signing In CI | 1 | 1 + capstone | CI |

The order follows one signature from start to end: what happens when you sign
keylessly, which identity a workload signs as, how a verifier checks that
identity exactly, and how a pipeline does all of it without a stored key.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Sign Without A Long-Lived Key](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Sign As A Kubernetes Workload](sections/section-020/module-01/course.md) | 2 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Verify Exactly Who Signed](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Sign In CI Without A Stored Key](sections/section-040/module-01/course.md) | 2 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair A Keyless Signing Setup | token audience, signing configuration, a key-based bundle |
| [020](sections/section-020/capstone/labs/lab-01) | Sign Two Images With Their Own Identities | default service account, token audience, a tag instead of a digest |
| [030](sections/section-030/capstone/labs/lab-01) | Verify Which Repository Built A Public Image | an organisation-wide identity check that accepts too much |
| [040](sections/section-040/capstone/labs/lab-01) | Move A Pipeline From A Signing Key To Keyless | a key in a Secret, a key-based Job and a key-based verification script |

---

## The lab environment

Every playground and lab is a **kind** cluster with:

- a private Sigstore stack: Fulcio, Rekor v1 with Trillian and MySQL 8.4, a
  certificate transparency log. Fulcio trusts the cluster's own service
  account tokens, so a pod signs keylessly with a projected token and no
  browser;
- an OCI registry at `registry.localtest.me:5001` (plain HTTP, lab-only);
- the `workstation` pod with `cosign`, `rekor-cli`, `regctl`, `jq` and
  `openssl`, the trust files in `/etc/sigstore` and a token in
  `/var/run/sigstore/token`.

Each environment needs about **6 GiB** of memory and up to 15 minutes for the
first start. The shared install script is
`bootstrap/install-sigstore.sh` (playgrounds) or
`bootstrap/01-install-sigstore.sh` (labs) and is identical everywhere.

## Running a playground or a lab

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/<section>/module-01/playground
astrona destroy <name>

astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/<section>/module-01/labs/lab-01
astrona submit -c sections/<section>/module-01/labs/lab-01
astrona destroy <name>
```

Graders check behaviour: a signature must verify for the exact expected
identity and issuer, with its transparency log entry, and must fail for every
other identity. They reject `--insecure-ignore-tlog`, identity patterns that
accept more than one workload, and long-lived keys.
