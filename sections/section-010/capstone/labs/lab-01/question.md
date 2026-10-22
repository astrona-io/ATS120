# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Keyless flow

## Scenario

The inventory team published the release bundle for `inventory-1.0.tar.gz` in the ConfigMap `release-bundle`, but a consumer reports that `cosign verify-blob` cannot find any certificate in it. While looking into it, the team also found that the workstation can no longer sign keylessly at all. Someone "tidied up" the workstation's configuration last week.

The release file is in the workstation at `/work/release/inventory-1.0.tar.gz`, and an exact copy is in the ConfigMap `release-files` in the namespace `workstation`.

## Your task

1. Find out why the published bundle has no certificate.
2. Find every reason the workstation can no longer sign keylessly, and fix them. Read cosign's error messages and the token itself.
3. Sign the release file keylessly as the workstation and replace the bundle in the ConfigMap `release-bundle` (key `inventory-1.0.tar.gz.sigstore.json`).

## Constraints

- Fix the existing objects. Do not rebuild the trust files from scratch, and do not change `trusted-root.json`.
- **Keyless only.** Do not create or use a key pair.
- Do not turn off the transparency log upload, and never verify with an `--insecure` flag.
- Do not change the release file or the ConfigMap `release-files`.

## Done when

- The workstation's projected token is issued for the audience `sigstore`.
- `signing-config.json` in the ConfigMap `sigstore-trust` (namespace `workstation`) names the Fulcio that runs in the cluster.
- The bundle in `release-bundle` holds a Fulcio certificate for `https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation`.
- `cosign verify-blob` accepts the bundle for that identity and the cluster's issuer, and rejects it for any other identity.
