---
estimated_duration: 20m
---

# Sign As The Release Bot

- **Slug:** ats-120-lab-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab in the namespace(s) `ci` and `workstation`. Read `question.md` for the task;
`solution.md` is the walkthrough. The environment needs about 6 GiB and up to
15 minutes to start.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-120-lab-020-01
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-sigstore.sh` | Shared install, the same in every environment of ATS120 |
| `bootstrap/02-seed-state.sh` | The starting state |
| `manifests/` | Registry, namespaces, workstation, Helm values |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `validation/` | Grading scripts, one per check |
