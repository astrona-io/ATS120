# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Verification

## Scenario

The platform team mirrors Flux's source-controller into its own registry and wants an admission step that accepts `ghcr.io/fluxcd/source-controller` images only when they were built by Flux's GitHub Actions in the repository `fluxcd/source-controller`. A colleague copied the check from the Flux documentation into the ConfigMap `verify-flux-org` (namespace `workstation`). It accepts every image the `fluxcd` organisation signs, including the kustomize-controller.

The ConfigMap `verify-flux` (namespace `workstation`, key `verify-flux.sh`) holds an empty script for the stricter check. This task needs outbound internet: the images are on `ghcr.io`, and cosign uses the public-good Sigstore trust root.

## Your task

1. Read the certificate claims Fulcio recorded for `ghcr.io/fluxcd/source-controller:v1.9.6`, and find the claim that tells the controllers apart.
2. Write `verify-flux.sh IMAGE` so it exits `0` only when `IMAGE` was signed in GitHub Actions in the repository `fluxcd/source-controller`.
3. Store it in the ConfigMap `verify-flux` under the key `verify-flux.sh`.

## Constraints

- Pin the GitHub Actions issuer, `https://token.actions.githubusercontent.com`.
- Verify against the public-good trust root (cosign's default), not the private stack's trusted root.
- Do not use any `--insecure` flag.

## Done when

- The script exits `0` for `ghcr.io/fluxcd/source-controller:v1.9.6`.
- The script exits with an error for `ghcr.io/fluxcd/kustomize-controller:v1.9.6`.
- The script pins the GitHub Actions issuer and uses no `--insecure` flag.
