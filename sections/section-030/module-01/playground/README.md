# Verifying Identities Precisely — Playground

- **Slug:** ats-120-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — no task, no grading

A sandbox with a private Sigstore stack (Fulcio, Rekor, CT log, Trillian), an
HTTP OCI registry and the `workstation` pod with `cosign`, `rekor-cli` and
`regctl`. The first start takes up to 15 minutes and about 6 GiB of memory.

## Run it

```sh
astrona run -c .
astrona destroy ats-120-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name`), not the path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/install-sigstore.sh` | Shared install, the same in every environment of ATS120 |
| `bootstrap/prepare.sh` | Playground extras |
| `manifests/` | Registry, namespaces, workstation, Helm values |
| `docs/overview.md` | The learner guide |
