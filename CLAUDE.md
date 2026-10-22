# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS120 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Keyless Signing With Fulcio & OIDC** domain of
  the **Sigstore** training path (`ATP023`). It is 25% of the path. There is
  no official Sigstore certification exam; the path's domains and weights are
  Astrona's own, set in `ATP023/path.yaml`.
- **What the domain really tests:** signing without a long-lived key and
  proving who signed. The student must *do* things: read an OIDC identity
  token, sign keylessly with a workload identity, read the identity Fulcio put
  in a certificate, verify with an exact identity and issuer, and run the
  signer as its own workload in a CI job. Every fix is proved with a
  `cosign verify` that passes for the right identity and fails for any other.
- **The four topics:** how keyless signing works, signing with a workload
  identity, verifying identities precisely, and keyless signing in CI.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | How Keyless Signing Works | Keyless flow |
  | 020 | Signing With A Workload Identity | Workload identity |
  | 030 | Verifying Identities Precisely | Verification |
  | 040 | Keyless Signing In CI | CI |

- **The versions:** `cosign` **v3.1.4** (client and the
  `ghcr.io/sigstore/cosign/cosign:v3.1.4` image), `regctl` 0.11.7, and a
  private Sigstore stack installed with the `scaffold` Helm chart **0.6.117**
  and Helm 3.22.1. The chart pins its own server versions: **Fulcio v1.9.0**,
  **Rekor v1.5.4** (Rekor v1 with Trillian 1.8.0), the CT log 0.7.33 (Trillian
  CTFE, created by the scaffolding jobs). The newest releases (Fulcio v1.9.1,
  Rekor v1.5.5) are not what runs; teach what runs. The public example image
  is `ghcr.io/fluxcd/source-controller:v1.9.6` (from Flux v2.9.6), signed in
  GitHub Actions.
- **The main sources:** <https://docs.sigstore.dev/> (Cosign signing and
  verifying, the certificate authority overview and its OIDC usage, the CI
  quickstart), the `sigstore/fulcio` source at v1.9.0 (identity and
  certificate extensions), the `sigstore/cosign` docs at v3.1.4 (`doc/`
  folder: exact flags), and the `sigstore/helm-charts` `scaffold` chart.
  Sigstore is an OpenSSF project under the Linux Foundation, not a CNCF
  project.

### Status: built, not yet run

The first version of this repository was written from the documentation and
the sources **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The biggest open risk is **Fulcio trusting the kind service account issuer**
(see "Environment facts"). Check that first: sign once from the workstation and
read the Fulcio log. If it fails, the fallback is a Dex OIDC issuer in the
cluster, with email identities instead of service account identities.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Keyless signing | Signing with a key pair that lives only for one signing operation, bound to an identity by a short-lived certificate |
| Ephemeral key | The key pair cosign creates for one signature and throws away afterwards |
| OpenID Connect (OIDC) | A protocol that issues signed ID tokens that say who a user or workload is |
| ID token | A JSON Web Token (JWT) from an OIDC provider; its claims include `iss`, `sub`, `aud` and `exp` |
| Issuer (`iss`) / subject (`sub`) / audience (`aud`) | Who issued the token / who it is about / which service it is meant for (`sigstore` for Fulcio) |
| Ambient credentials | An ID token the platform gives a workload without any stored secret, such as a GitHub Actions token or a projected Kubernetes service account token |
| Projected service account token | A Kubernetes service account token written into a pod file, with an audience and an expiry the pod spec chooses |
| Fulcio | Sigstore's certificate authority: it checks the ID token and issues a certificate for the ephemeral public key, valid for about 10 minutes |
| Proof of possession | The signed challenge cosign sends with the certificate request, proving it holds the private key |
| Subject Alternative Name (SAN) | The certificate field that carries the identity: an email address or a URI |
| Fulcio extensions | Certificate extensions under OID `1.3.6.1.4.1.57264.1` that record the OIDC issuer and, for CI tokens, claims such as the repository and workflow |
| CT log / SCT | The certificate transparency log Fulcio writes every certificate to / the signed certificate timestamp embedded in the certificate as proof |
| Transparency log (Rekor) | The append-only log of signing events; its entry proves the signature was made while the certificate was valid |
| Trusted root / signing config | `trusted_root.json`: the keys and certificates a verifier trusts / `signing_config.json`: which Fulcio and Rekor a signer uses |
| `--certificate-identity` / `--certificate-oidc-issuer` | The exact identity and issuer a keyless signature must have to pass `cosign verify`; the `-regexp` variants accept a regular expression |

### The example workloads

| Name | What it is |
| --- | --- |
| `registry` (namespace `registry`) | `registry:3.1.2`, plain HTTP on port `5001`, reached in the cluster as `registry.localtest.me:5001`. Lab-only: cosign needs `--allow-http-registry` |
| Private Sigstore stack | Helm release `sigstore` (namespace `sigstore-system`, chart `scaffold`), with Fulcio in `fulcio-system` (Service `fulcio-server`, port `80`), Rekor in `rekor-system` (Service `rekor-server`, port `80`), the CT log in `ctlog-system` (Service `ctlog`, prefix `sigstorescaffolding`) and Trillian with MySQL 8.4 in `trillian-system` |
| ConfigMap `sigstore-trust` | In `workstation`, `ci` and every namespace that signs: `trusted-root.json`, `signing-config.json` and `oidc-issuer` (the cluster's service account issuer URL), built by the bootstrap |
| `workstation` (namespace `workstation`, service account `workstation`) | `alpine:3.22` with `cosign`, `rekor-cli`, `regctl`, `curl`, `jq`, `openssl`; `/etc/sigstore` holds the trust files; `/var/run/sigstore/token` holds a projected token with audience `sigstore`. Its keyless identity is `https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation` |
| Namespace `ci` | Service accounts for CI signers (`release-bot`, `ci-builder` and others per lab); signers run as Jobs with the `ghcr.io/sigstore/cosign/cosign:v3.1.4` image |
| Image `registry.localtest.me:5001/inventory/podinfo:6.15.0` | Copied from `ghcr.io/stefanprodan/podinfo:6.15.0` (`linux/amd64` only) at start |

Pages run tools through a helper, defined once per page that needs it, plus
the shared flags:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
```

Inside the workstation shell (`kubectl -n workstation exec -it deploy/workstation -- sh`)
the files are `/etc/sigstore/trusted-root.json`, `/etc/sigstore/signing-config.json`,
`/etc/sigstore/oidc-issuer` and `/var/run/sigstore/token`.

### Environment facts the text must respect

- **Fulcio trusts the cluster's own service account issuer.** The bootstrap
  reads the issuer from `kubectl get --raw /.well-known/openid-configuration`
  (on kind it is normally `https://kubernetes.default.svc.cluster.local`) and
  writes it into Fulcio's configuration as type `kubernetes`, client ID
  `sigstore`. The configuration also keeps the entry
  `https://kubernetes.default.svc`, because Fulcio v1.9.0 trusts the cluster
  CA only when that entry exists (`pkg/config/config.go`).
- **Fulcio runs without its own token** (`server.serviceAccount.mountToken:
  false`). With a token mounted, Fulcio v1.9.0 sends it only to the issuer's
  host and refuses any other host, and the API server's JWKS URL on kind is
  the node address, not the issuer host. Without a token Fulcio fetches the
  discovery document and JWKS anonymously, which the ClusterRoleBinding
  `oidc-reviewer` (`system:service-account-issuer-discovery` to
  `system:unauthenticated`) allows. That binding exposes only public keys; say
  so on the page that shows it.
- **The identity in the certificate** for a Kubernetes token is the URI SAN
  `https://kubernetes.io/namespaces/<namespace>/serviceaccounts/<name>`
  (`pkg/identity/kubernetes/principal.go` at v1.9.0), and the issuer extension
  carries the token's `iss`.
- **Trust files instead of TUF.** The stack runs no TUF server. The bootstrap
  builds `trusted-root.json` with `cosign trusted-root create` (Fulcio root
  from the Secret `fulcio-server-secret` key `cert`, Rekor key from
  `/api/v1/log/publicKey`, CT log key from the Secret `ctlog-public-key` key
  `public`) and `signing-config.json` with `cosign signing-config create`.
  Pages pass `--trusted-root` and `--signing-config` explicitly. Explain once
  that the public-good instance distributes the same two files through TUF.
- **Tokens:** projected tokens have audience `sigstore` and
  `expirationSeconds: 3600`; the kubelet renews the file. cosign reads it with
  `--identity-token /var/run/sigstore/token`.
- **The public-good instance is optional and ungraded.** Verifying
  `ghcr.io/fluxcd/source-controller:v1.9.6` uses cosign's default public trust
  root (fetched over TUF from the internet). No lab signs against the
  public-good Fulcio.
- **Trillian's MySQL** uses the 8.4 image digest and probes from the
  `sigstore/helm-charts` CI values, because MySQL 5.7 runs out of memory on
  newer kind nodes.
- **CoreDNS:** copy the `rewrite stop` block for `registry.localtest.me` from
  `sections/section-010/module-01/playground/bootstrap/install-sigstore.sh`;
  never the one-line `rewrite name` form.
- **Allow about 6 GiB** for an environment and up to 15 minutes for the first
  start (Trillian, MySQL, Redis, Fulcio, Rekor and the CT log).

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/install-sigstore.sh`, `bootstrap/prepare.sh`,
`manifests/lab-start.yaml`, `manifests/workstation.yaml`,
`docs/overview.md`), labs (`config.yaml`, `README.md`, `prerequisites.md`,
`question.md`, `solution.md`, `bootstrap/01-install-sigstore.sh`,
`bootstrap/02-seed-state.sh`, `manifests/`, `solution/apply.sh`,
`testing/wait-for-sigstore.sh`, `validation/validate-*.sh`) and one capstone
per section.

`01-install-sigstore.sh` (and the playground's `install-sigstore.sh`) is the
same in every environment, generated from one source. Change it everywhere at
once.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS120`, domain `Keyless Signing With Fulcio & OIDC`,
weight `25`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `keyless-flow`, `oidc`, `fulcio`,
  `workload-identity`, `verification`, `ci`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `keyless`, `ephemeral-key`,
  `oidc-token`, `projected-token`, `token-audience`, `fulcio`,
  `fulcio-certificate`, `san`, `fulcio-extensions`, `ct-log`, `rekor`,
  `bundle`, `sign-blob`, `verify-blob`, `cosign-sign`, `cosign-verify`,
  `certificate-identity`, `certificate-oidc-issuer`, `identity-regexp`,
  `github-actions`, `github-claims`, `service-account`, `ci-job`,
  `trusted-root`, `signing-config`, `digest`, `key-migration`.
- `resources`: 1 to 4 pages on `docs.sigstore.dev`, `docs.github.com`,
  `kubernetes.io` or `fluxcd.io`. The only place outside links are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-010/module-01/playground
astrona destroy ats-120-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-120-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-120-playground-<section>-<module>`, `ats-120-lab-<section>-<module>`,
`ats-120-capstone-<section>`. Graders check **behaviour**: `cosign verify`
or `verify-blob` passes with the exact expected identity and issuer and the
transparency log entry, and fails for every other identity. They reject the
plausible but wrong fix: `--insecure-ignore-tlog` or `--insecure-ignore-sct`,
an identity regexp that matches more than one workload, a long-lived key, a
signature from the workstation where a CI identity was asked for, signing a
tag instead of the digest given. A lab's `question.md` and `solution.md` must
match what its `validation/` scripts check.

### Where to find trusted sources

- **Keyless and OIDC:** <https://docs.sigstore.dev/cosign/signing/overview/>,
  <https://docs.sigstore.dev/certificate_authority/overview/>,
  <https://docs.sigstore.dev/certificate_authority/oidc-in-fulcio/>,
  <https://docs.sigstore.dev/cosign/verifying/verify/>
- **CI:** <https://docs.sigstore.dev/quickstart/quickstart-ci/>,
  <https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect>
- **Kubernetes tokens:** <https://kubernetes.io/docs/concepts/storage/projected-volumes/>
- **Sources:** `sigstore/fulcio` at v1.9.0 (`pkg/config/config.go`,
  `pkg/identity/kubernetes/principal.go`, `docs/oid-info.md`),
  `sigstore/cosign` at v3.1.4 (`doc/`), `sigstore/helm-charts`
  (`charts/scaffold`, `charts/fulcio`).
