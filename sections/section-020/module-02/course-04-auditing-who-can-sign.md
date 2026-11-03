# Auditing Who Can Sign

Permissions drift. A temporary binding becomes permanent, a group grows, a new role is added. This part shows how to list who can currently run pods or create tokens in a signing namespace, and how to find the bindings that grant it.

## List the bindings of the namespace

Start with the role bindings in `ci`, with their subjects:

<!-- astrona:playground:renew -->

```sh
kubectl -n ci get rolebindings -o json \
  | jq -r '.items[] | "\(.metadata.name): \(.roleRef.kind)/\(.roleRef.name) -> \([.subjects[]? | "\(.kind) \(.name)"] | join(", "))"'
```

Each line shows a binding, the role it grants and its subjects. Look for roles such as `edit` and `admin`, and for custom roles that mention `pods` or `serviceaccounts/token`.

Cluster role bindings apply to every namespace and need their own look:

```sh
kubectl get clusterrolebindings -o json \
  | jq -r '.items[] | select(.roleRef.name | IN("edit", "admin", "cluster-admin")) | "\(.metadata.name): \(.roleRef.name) -> \([.subjects[]? | "\(.kind) \(.name)"] | join(", "))"'
```

## Check one subject

For a subject you suspect, `kubectl auth can-i --list` prints everything it may do in a namespace:

```sh
kubectl auth can-i --list -n ci --as dev-user
```

Read the list for `pods` and `serviceaccounts/token` rows that include `create`. An empty answer for both means the subject cannot sign as a workload.

## Who is allowed to impersonate

`kubectl --as` is itself a permission: `impersonate` on `users`, `groups` or `serviceaccounts`. A subject that may impersonate `system:serviceaccount:ci:release-bot` can act as the service account against the API server, and that includes creating pods. Check for it when you review a cluster:

```sh
kubectl get clusterroles -o json \
  | jq -r '.items[] | select(.rules[]? | (.verbs // []) | index("impersonate")) | .metadata.name'
```

## Make the audit a routine

An audit that runs once finds the state of one day. Put the three commands in a scheduled job or a review checklist, and compare their output with the last run. A change in the subjects of a signing namespace is the event to look at.

## Common pitfalls

> [!WARNING]
> - **Auditing only role bindings.** Cluster role bindings, groups and impersonation reach the namespace too.
> - **Stopping at "who has edit".** Custom roles can grant `pods` or `serviceaccounts/token` without the name `edit`.
> - **Auditing once.** The state changes. Repeat the check.

## Your mission: Close The Door Around The Release Signer

You can now find and limit who can sign as a workload. The graded lab gives you a namespace where a developer account can sign as the release bot and asks you to close that path without breaking the pipeline.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-120-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-120-lab-020-02
astrona start ats-120-playground-020-02
```
