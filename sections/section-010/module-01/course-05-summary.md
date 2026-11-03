# Summary

Keyless signing removes the long-lived signing key instead of protecting it better. cosign creates a key pair for one signature and deletes the private key right after. Fulcio, the Sigstore certificate authority, binds the public key to an identity with a certificate that is valid for about ten minutes. Two logs make the result public: the certificate transparency log records the certificate, and Rekor records the signature.

The identity comes from an OpenID Connect (OIDC) ID token, a signed JSON Web Token from an identity provider. Its `iss` claim names the issuer, `sub` the subject, `aud` the audience and `exp` the expiry. Fulcio checks the token's signature with the issuer's public keys, which it finds through the discovery document and the JSON Web Key Set. It also checks that the audience is the client ID it is configured for, here `sigstore`. A Kubernetes projected service account token is an ambient credential: the platform writes it into the pod, so no secret is stored anywhere.

Fulcio writes the identity into the certificate's Subject Alternative Name. For a Kubernetes token it is the URI `https://kubernetes.io/namespaces/<namespace>/serviceaccounts/<name>`, without the pod name. It writes the issuer into the extension `1.3.6.1.4.1.57264.1.8`. A verifier needs both, because an identity means little without the issuer that vouched for it.

A ten-minute certificate stays useful for years because of the transparency log. Rekor signs the time it added the signature, and the verifier checks that this time lies inside the certificate's window. The Sigstore bundle carries everything a verifier needs: the signature, the certificate and the log entry. The key facts to remember are these:

- Keyless verification needs the expected identity and issuer; never verify with a pattern that accepts anything.
- Never skip the transparency log: without it there is no trusted signing time.
- A private Sigstore stack needs its own trusted root and signing configuration.
- Publish the bundle next to the artifact it belongs to.

<!-- astrona:playground:destroy -->
