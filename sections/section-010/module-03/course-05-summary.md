# Summary

A verifier trusts the anchors in its trusted root: the Fulcio certificate authorities, the Rekor keys, the certificate transparency log keys and, optionally, timestamp authorities. Every proof in a bundle needs a matching anchor, so one missing list makes verification fail even when the signature is good. A signer reads a separate file, the signing configuration, which lists the certificate authority, OIDC provider, transparency log and timestamp authority URLs it may call.

The two files do different jobs and must match: every service a signer uses needs its key in the trusted root. A connection error while signing points at the signing configuration. A trust error while verifying points at the trusted root.

Each anchor has a validity range. A rotation adds a new key and ends the old one, and the old one stays in the file so old signatures keep verifying against the integrated time of their log entry. On the public internet, The Update Framework delivers the trusted root in a chain of signed files that ends at a root shipped with cosign. A private stack must protect its own delivery path. The key facts to remember are these:

- The trusted root is for verifying; the signing configuration is for signing.
- Never delete old anchors after a rotation.
- Limit who can edit the trust files.

<!-- astrona:playground:destroy -->
