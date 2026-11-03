# Roles That Let Someone Sign

The built-in cluster roles are bound to people every day. This part checks which of them, once bound in the namespace `ci`, allow signing as `ci/release-bot`, using `kubectl auth can-i`.

## Asking the API server

`kubectl auth can-i VERB RESOURCE` asks whether the current user may do something. With `--as USER` you ask for another user, which needs the permission to impersonate, and a cluster administrator has it. Check the two permissions for the two users of the playground:

<!-- astrona:playground:renew -->

```sh
kubectl auth can-i create pods -n ci --as pipeline-user
kubectl auth can-i create serviceaccounts/token -n ci --as pipeline-user
kubectl auth can-i create pods -n ci --as dev-user
kubectl auth can-i create serviceaccounts/token -n ci --as dev-user
```

Each command prints `yes` or `no`. For `pipeline-user`, bound to `edit`, both answers are `yes`. For `dev-user`, bound to `view`, both are `no`.

## What the roles contain

Print the rules of the `edit` role and look for the two resources:

```sh
kubectl get clusterrole edit -o json | jq -r '.rules[] | select((.resources // []) | any(. == "pods" or . == "serviceaccounts/token")) | "\(.resources | join(",")): \(.verbs | join(","))"'
```

The `edit` role grants `create` on `pods` and on `serviceaccounts/token`. The `view` role grants only `get`, `list` and `watch` and does not include `serviceaccounts/token`. The `admin` role contains everything `edit` does. Many other roles that people call "read and write", including some custom ones built from `edit`, also allow signing.

## Why edit rights are signing rights

The result can be surprising: a developer who may edit workloads in `ci` for an unrelated reason can create a pod as `release-bot` and sign an image the pipeline never built. The signature is genuine, because Fulcio did nothing wrong. The weakness is in who holds the permissions.

There are three ways to reduce it:

| Measure | Effect |
| --- | --- |
| Bind people to `view` in the signing namespace | They can read but not run workloads or mint tokens |
| Keep the signing service account alone in its own namespace | Nobody else has a reason to hold `edit` there |
| Deny creating pods that use a given service account with an admission policy | Only the pipeline's identity may do it |

## Common pitfalls

> [!WARNING]
> - **Checking only your own permissions.** Use `--as` for the subjects you want to know about, not the administrator that runs the check.
> - **Reading `no` for a group.** `--as USER` can also take `--as-group GROUP`. A user may hold rights through a group you did not name.
> - **Believing a ClusterRoleBinding is a namespaced right.** A cluster role bound with a ClusterRoleBinding applies in every namespace, `ci` included.
