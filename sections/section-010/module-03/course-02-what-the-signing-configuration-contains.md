# What The Signing Configuration Contains

The trusted root tells a verifier what to trust. The signing configuration tells a signer where to go. When signing fails with a connection or a configuration error, this is the file to read.

## The service lists

A **signing configuration** (`signing_config.json`) lists the services a signer may call, each with a URL, an API version and a start time. The lists are the certificate authorities (`caUrls`), the OIDC providers (`oidcUrls`), the transparency logs (`rekorTlogUrls`) and the timestamp authorities (`tsaUrls`). Two more fields, `rekorTlogConfig` and `tsaConfig`, say how many of the listed services the signer must use.

<!-- astrona:playground:renew -->

Read the file in your playground. Open a shell in the workstation:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Print the service URLs:

```sh
jq '{mediaType, caUrls, rekorTlogUrls, rekorTlogConfig, tsaUrls}' /etc/sigstore/signing-config.json
```

The output shows the Fulcio and Rekor Services of the private stack, with `majorApiVersion` and a `validFor` start time for each. The URLs point to Services inside the cluster, which is why the same file does not work on your laptop outside the cluster.

## What a signer does with it

When you pass `--signing-config`, cosign reads the file and picks a service from each list whose time range is current. It requests the certificate from the chosen Fulcio and uploads the entry to the chosen Rekor. A signer can only use a Rekor that the trusted root also lists, because the entry proof must verify later. The two files therefore have to match: every service in the signing configuration needs its anchor in the trusted root.

Change the Fulcio URL in a copy of the file and see the failure. Make a copy with a wrong host name and sign with it:

```sh
sed 's#fulcio-server.fulcio-system#fulcio.fulcio-system#' /etc/sigstore/signing-config.json > /tmp/bad-signing-config.json
cosign sign-blob --yes --identity-token /var/run/sigstore/token \
  --signing-config /tmp/bad-signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  /work/release/inventory-1.0.tar.gz
```

The command fails when it tries to reach the certificate authority, before any Rekor call. The error names a connection problem for the wrong host. A failure at this step points at the signing configuration and not at the token.

## Signing configuration versus trusted root

Remember the split. The signing configuration is used only when signing. The trusted root is used only when verifying. A verifier on another machine never needs your signing configuration, and a signer does not need the trusted root to sign (cosign uses it to check what it received).

You now know where a signer finds its services. The open question is why every entry has a time range.

## Common pitfalls

> [!WARNING]
> - **Reading a signing failure as a token problem.** If the connection fails, check the URLs in the signing configuration first.
> - **Listing a service that the trusted root does not know.** Signing works, and verification later fails.
> - **Giving a verifier the signing configuration.** It does not hold any key a verifier can use.
