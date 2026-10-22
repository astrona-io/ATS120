# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Verification

## Scenario

The deployment step runs `verify-release.sh IMAGE` before it ships an image, and ships only if the script exits with `0`. The script is stored in the ConfigMap `verify-release` in the namespace `workstation`, under the key `verify-release.sh`.

An audit found that the script accepts `inventory/podinfo:6.15.0-rc1`, which a pipeline in the namespace `build` signed. Only the release bot in the namespace `ci` may ship.

The registry holds three signed images: `inventory/podinfo:6.15.0` (signed by `ci/release-bot`), `inventory/podinfo:6.15.0-rc1` (signed by `build/release-bot`) and `inventory/podinfo:6.15.0-hotfix` (signed by the workstation).

## Your task

1. Find out which images the current script accepts, and why.
2. Change the script so it accepts an image only when it was signed by `https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot` through this cluster's issuer, the URL in `/etc/sigstore/oidc-issuer`.
3. Store the new script in the ConfigMap `verify-release` under the same key.

## Constraints

- The script still takes the image as its only argument and still verifies with the private stack's trusted root, `/etc/sigstore/trusted-root.json`.
- Do not use any `--insecure` flag.
- Do not re-sign or delete any image or signature.

## Done when

- The script exits `0` for `registry.localtest.me:5001/inventory/podinfo:6.15.0`.
- The script exits with an error for `inventory/podinfo:6.15.0-rc1` and `inventory/podinfo:6.15.0-hotfix`.
- The script pins the issuer and uses no `--insecure` flag.
