# Summary

An attestation is a signed statement about one digest. The in-toto statement holds a subject (the digest), a predicate type (the kind of claim) and the predicate (the claim). A DSSE envelope signs the statement together with its payload type. With keyless signing the signature, the Fulcio certificate and the Rekor `dsse` entry travel in a Sigstore bundle attached to the image.

`cosign attest --predicate FILE --type TYPE` creates an attestation, with the same token and trust flags as `cosign sign`. `cosign verify-attestation --type TYPE` checks the signer with the same identity and issuer flags as `cosign verify`, then prints the envelopes that passed. The statement is the base64 `payload`; decode it with `base64 -d` and read the predicate with `jq`. A valid signature does not make a claim true, so check the content and trust each signer only for the claims it should make.

A cluster can enforce both checks at admission with the sigstore policy controller, whose `ClusterImagePolicy` lists image patterns and keyless authorities with issuer and subject. The key facts to remember are these:

- The subject binds a claim to one digest.
- Pin the signer of an attestation exactly as you pin the signer of a signature.
- Check the predicate content, not only the signature.
- Admission policy applies the checks to every pod.

<!-- astrona:playground:destroy -->
