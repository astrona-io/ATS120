# Control Who Can Sign As A Workload

A signature names a service account. That makes the service account worth protecting: anyone who can run a pod as it, or ask the API server for a token for it, can produce signatures with its identity. Keyless signing removes the stored key, but the access that the key used to guard moves into Kubernetes role-based access control (RBAC).

This module shows exactly which permissions allow signing as a service account, how to check them with `kubectl auth can-i`, how the namespace and name in the identity limit the damage, and how to audit who holds the permissions today.

The module has four parts. **Who Can Get A Token For A Service Account** explains the two ways to obtain a token. **Roles That Let Someone Sign** checks the built-in roles. **Separate Signers By Namespace And Name** shows how the identity limits what a verifier accepts. **Auditing Who Can Sign** lists the subjects that hold the permissions. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Name the two Kubernetes permissions that let a subject sign as a service account.
- Mint a short-lived token for a service account with `kubectl create token`.
- Check what a user can do with `kubectl auth can-i` and `--as`.
- Explain which built-in roles allow signing and which do not.
- Explain why the namespace is part of the signing identity.
- List the subjects that can run pods or create tokens in a namespace.

## Before you start

You need to know the identity Fulcio writes for a service account, and how a signing Job runs. You also need the basics of RBAC: roles, cluster roles, role bindings and subjects (users, groups and service accounts).

Your playground is the same private Sigstore stack. The namespace `ci` has the service account `release-bot`. The playground adds two users to the namespace `ci` through role bindings: `pipeline-user`, bound to the cluster role `edit`, and `dev-user`, bound to the cluster role `view`. Users are plain names for the API server here, so you test them with `--as`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
