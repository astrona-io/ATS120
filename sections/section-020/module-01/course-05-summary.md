# Summary

A container image signature must cover the image's digest, the SHA-256 hash that names one exact content, because a tag can be moved to other content at any time. cosign v3 stores the signature in the registry as a Sigstore bundle in a separate artifact that refers to the image digest; signing never changes the image. `cosign tree` shows what is attached to an image, and signatures from several signers can sit side by side.

With keyless signing, the identity in the certificate comes from the signer's token. For a Kubernetes projected service account token, Fulcio writes `https://kubernetes.io/namespaces/<namespace>/serviceaccounts/<name>`. The service account a pod runs as therefore decides the identity of its signatures, and whoever may run pods as that service account may sign as it. Give every signer its own service account and limit who can create pods in its namespace.

A signing Job needs no key and no Secret. It runs the cosign image as its own service account, gets a projected token with the audience `sigstore`, mounts the trust files, and signs the digest it reads from a ConfigMap. A verifier then asks one precise question: is this digest signed by this identity, through this issuer? Signatures from other identities on the same image do not change the answer. The key facts to remember are these:

- Sign digests, not tags.
- A Job without `serviceAccountName` signs successfully, as `default`: the wrong identity.
- A token with the wrong audience makes Fulcio refuse the request.
- Verify with the exact identity and issuer; "is it signed?" is the wrong question.

<!-- astrona:playground:destroy -->
