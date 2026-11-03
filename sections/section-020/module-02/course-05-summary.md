# Summary

A keyless signature names the service account that produced the token. Two Kubernetes permissions give access to a token for a service account: `create` on `pods` (or on a workload that makes pods) in its namespace, and `create` on `serviceaccounts/token`. Anyone who holds either permission can sign as the service account, and Fulcio will issue a genuine certificate for it. The built-in roles `edit` and `admin` include both; `view` includes neither.

`kubectl auth can-i VERB RESOURCE -n NAMESPACE --as SUBJECT` shows what a subject may do, and `kubectl auth can-i --list` shows everything. Impersonation rights act as the service account too. To limit signing, bind people to `view` in the signing namespace, keep the signing service account in a namespace the pipeline owns, and give each kind of signature its own service account.

The identity contains the namespace and the name, and the certificate contains the issuer. A verifier that pins all three cannot be satisfied by a service account with the same name in another namespace or another cluster. Audit the bindings, the cluster role bindings and the impersonation rights of a signing namespace on a schedule. The key facts to remember are these:

- Two permissions allow signing: create pods, and create `serviceaccounts/token`.
- `edit` and `admin` allow signing; `view` does not.
- Pin namespace, name and issuer.
- Audit regularly; permissions drift.

<!-- astrona:playground:destroy -->
