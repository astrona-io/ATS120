# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Keyless flow

## Scenario

The release file `inventory-1.0.tar.gz` was signed keylessly, and its Sigstore bundle is published in the ConfigMap `release-bundle` in the namespace `workstation` (key `inventory-1.0.tar.gz.sigstore.json`). The file is in the ConfigMap `release-files`. An auditor asks for the exact place of this signature in the transparency log and for the identity that made it.

## Your task

1. Read the bundle and find the log index of its Rekor entry.
2. Check that the Rekor server of the cluster has an entry at that index.
3. Read the identity in the bundle's certificate.
4. Create a ConfigMap named `rekor-findings` in the namespace `workstation` with two keys: `logIndex` (the log index) and `identity` (the identity URI from the certificate).

## Constraints

- Read the values from the bundle and the log. Do not sign the file again: a new signature has a new log index.
- Do not change `release-files` or `release-bundle`.

## Done when

- `rekor-findings` has `logIndex` equal to the log index in the bundle, and Rekor has an entry at that index.
- `rekor-findings` has `identity` equal to the identity URI in the certificate.
- The bundle still verifies for that identity.
