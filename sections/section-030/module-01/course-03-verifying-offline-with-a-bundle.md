# Verifying Offline With A Bundle

Some verifiers cannot reach the internet: an air-gapped cluster, a build step behind a strict firewall, an auditor's laptop. They still need to check signatures. A Sigstore bundle together with a trusted root holds everything a verifier needs, so no request to Fulcio or Rekor is necessary. This part shows what makes that possible, verifies a file that way, and ends with a check you will tighten in the lab.

## What the verifier needs

To accept a keyless signature, a verifier checks five things. Each one needs a piece of evidence, and each piece is either in the bundle or in the trusted root:

| Check | Evidence | Where it is |
| --- | --- | --- |
| The certificate was issued by Fulcio | Fulcio's root certificate | Trusted root |
| The certificate was logged | The signed certificate timestamp (SCT) and the CT log key | Certificate in the bundle, key in the trusted root |
| The signature was logged, and when | The Rekor entry with its signed time and inclusion proof | Bundle, Rekor key in the trusted root |
| The identity and issuer are right | The certificate's SAN and issuer extension | Bundle |
| The file is what was signed | The signature over the file's digest | Bundle |

Nothing in that table needs a network request. The Rekor entry in the bundle carries Rekor's own signature over the entry and a proof that the entry is in the log, so the verifier checks them with Rekor's public key instead of asking Rekor. That is why `cosign verify-blob` with `--bundle` and `--trusted-root` works offline.

## Verifying with only the three files

Sign a file in a workstation shell first, so you have a fresh bundle:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
echo "inventory 1.0 checksums" > /work/sums.txt
cosign sign-blob --yes --identity-token /var/run/sigstore/token \
  --signing-config /etc/sigstore/signing-config.json \
  --trusted-root /etc/sigstore/trusted-root.json \
  --bundle /work/sums.txt.sigstore.json /work/sums.txt
```

Now collect exactly the three files an offline verifier gets, the file, its bundle and the trusted root, in one folder:

```sh
mkdir -p /tmp/offline && cp /work/sums.txt /work/sums.txt.sigstore.json /etc/sigstore/trusted-root.json /tmp/offline/
ls /tmp/offline
```

Verify from that folder alone. The command names no Fulcio, no Rekor and no registry:

```sh
cd /tmp/offline
cosign verify-blob --bundle sums.txt.sigstore.json --trusted-root trusted-root.json \
  --certificate-identity https://kubernetes.io/namespaces/workstation/serviceaccounts/workstation \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" sums.txt
```

The verification succeeds. To convince yourself that no service was asked, scale Fulcio and Rekor to zero from your own machine in a second terminal with `kubectl -n fulcio-system scale deploy fulcio-server --replicas=0` and `kubectl -n rekor-system scale deploy rekor-server --replicas=0`, run the same command again, and scale them back to one afterwards. Signing needs the services; verifying with a bundle does not.

## When the trusted root changes

The one thing an offline verifier must keep current is the trusted root. When the operators of a Sigstore instance rotate a key, for example Fulcio's root or Rekor's signing key, the new key goes into a new trusted root, and old keys stay in it with an end date. A verifier with an outdated trusted root rejects new signatures it should accept. The public-good instance distributes its trusted root through The Update Framework (TUF) for exactly this reason; an offline verifier has to bring the update in another way, for example as a file in its release.

## Putting a check into a script

Teams rarely type `cosign verify` by hand; they put it in a script that a deployment step runs. The script is then the policy: whatever it accepts, ships. A script for the release image of this playground could look like this:

```sh
#!/bin/sh
# verify-release.sh IMAGE: exits 0 only when IMAGE was signed by ci/release-bot.
exec cosign verify \
  --trusted-root /etc/sigstore/trusted-root.json \
  --allow-http-registry \
  --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
  "$1"
```

`exec` makes the script's exit code the exit code of `cosign verify`, so the deployment step can rely on it. The script names the trusted root, the exact identity and the exact issuer, and nothing else. Every loosening you might be tempted to add, a regular expression, an issuer pattern, an `--insecure` flag, widens what ships.

You now know what makes a bundle verifiable without a network, what an offline verifier must keep current, and how a verification turns into a policy script. The open question is the lab's: what does a script that accepts too much look like, and how do you prove it accepts only the right signer?

## Common pitfalls

> [!WARNING]
> - **Dropping the bundle.** Without it, the verifier must fetch the signature and log entry from the network, and an air-gapped verifier cannot.
> - **A stale trusted root.** After a key rotation, an old trusted root rejects valid new signatures. Ship trusted root updates to offline verifiers on purpose.
> - **Using the private stack's trusted root for public images, or the other way round.** Each Sigstore instance has its own trusted root.
> - **A script that ignores the exit code.** Use `exec` or check `$?`; a script that always exits 0 accepts everything.

## Your mission: Tighten A Verification Script

You can now write identity checks that accept exactly one signer and put them into a script. The graded lab gives you a verification script that accepts images from two signers it should not, and asks you to tighten it until it accepts only the release bot in `ci` through this cluster's issuer.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-120-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-120-lab-030-01
astrona start ats-120-playground-030-01
```
