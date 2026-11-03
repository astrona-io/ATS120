# Summary

Fulcio receives an OIDC identity token and an ephemeral public key with a proof of possession, either as a signed certificate signing request or as a signature over the token subject. It checks the issuer, the token signature, the expiry, the audience and the proof, and then builds an identity from the claims. Fulcio never sees the signed artifact and does not decide who may sign what.

The certificate comes with a chain to a root certificate that the verifier holds in its trusted root. The short life of the leaf means a normal clock check fails soon after signing, so a verifier compares the certificate dates with the integrated time of the Rekor entry. Fulcio also logs each certificate in a certificate transparency log and embeds the signed certificate timestamp, which a verifier checks against the log key in its trusted root.

Rekor records the signature as an entry with a log index, an integrated time and a UUID. Anyone can search the log by artifact hash. A bundle holds a signed entry timestamp and an inclusion proof against a signed checkpoint, so a verifier needs no connection to the log. The key facts to remember are these:

- The proof of possession shows control of the ephemeral key, not rights over the artifact.
- The CT log records certificates; Rekor records signatures.
- Never switch off the SCT or transparency log checks to make a signature pass.

<!-- astrona:playground:destroy -->
