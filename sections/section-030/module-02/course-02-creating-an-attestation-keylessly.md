# Creating An Attestation Keylessly

`cosign attest` builds the statement, wraps it in an envelope, signs it with a Fulcio certificate and attaches it to the image. This part creates a scan attestation for the release image from the workstation.

## The predicate file

The predicate is a JSON file. For a scan result it can be small. Create it in the workstation and pick a predicate type for it:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Then, inside the shell:

```sh
cat > /tmp/scan.json <<'JSON'
{"scanner": "example-scanner", "critical": 0, "high": 2}
JSON
```

The values are an example. A real pipeline writes the output of its scanner here.

## Attest the digest

Give `cosign attest` the predicate, the type and a digest reference. The token and trust flags are the same as for `cosign sign`:

```sh
IMAGE=registry.localtest.me:5001/inventory/podinfo
cosign attest --yes --allow-http-registry \
  --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --predicate /tmp/scan.json --type custom \
  $IMAGE@$(regctl image digest $IMAGE:6.15.0)
```

`--type custom` gives the statement the predicate type `https://cosign.sigstore.dev/attestation/v1`. Other values for `--type` include `slsaprovenance`, `spdxjson`, `cyclonedx`, `vuln` and `openvex`, and a full URI also works for a type of your own. Choose the type that tells a reader how to read the file.

The command makes a Fulcio certificate for the workstation identity, as signing does. Look at the result with `cosign tree`, which now lists the attestation next to any signature.

## Who should attest what

The identity that creates an attestation is the identity that vouches for the claim. A scanner job should attest with the identity of the scanner, and a build job with the identity of the build. If one identity creates every claim, a leak of that identity forges all of them.

In a cluster, this is the same rule as for signing: one service account per kind of claim, and RBAC limits who can run pods as it.

## Common pitfalls

> [!WARNING]
> - **Attesting a tag.** Use the digest reference, as with signing.
> - **A predicate that is not valid JSON.** The command fails before it contacts Fulcio. Check the file with `jq . /tmp/scan.json`.
> - **Putting secrets in a predicate.** The predicate is stored in the registry and its digest goes into a public-style log. Do not include credentials or private data.
