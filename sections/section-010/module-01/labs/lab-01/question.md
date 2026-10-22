# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Keyless flow

## Scenario

The inventory team ships a release file, `inventory-1.0.tar.gz`. Consumers in the cluster want to check that the workstation built it, without being handed any public key. The team has decided to sign it keylessly and publish the Sigstore bundle in a ConfigMap.

The release file is in the workstation at `/work/release/inventory-1.0.tar.gz`. An exact copy is in the ConfigMap `release-files` in the namespace `workstation`.

## Your task

1. Sign `/work/release/inventory-1.0.tar.gz` keylessly as the workstation, with the private Sigstore stack, and write a Sigstore bundle.
2. Publish the bundle in a ConfigMap named `release-bundle` in the namespace `workstation`, under the key `inventory-1.0.tar.gz.sigstore.json`.
3. Check that the bundle verifies for the workstation identity and the cluster's issuer.

## Constraints

- **Keyless only.** Do not create or use a key pair.
- Do not turn off the transparency log upload; the bundle must hold a Rekor entry.
- Do not change the release file or the ConfigMap `release-files`.

## Done when

- The ConfigMap `release-bundle` holds a Sigstore bundle with at least one transparency log entry.
- The bundle's certificate names `https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation`.
- `cosign verify-blob` accepts the bundle for that identity and the cluster's issuer, and rejects it for any other identity.
