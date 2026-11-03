# Solution: Close The Door Around The Release Signer

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: `dev-user` cannot create pods, jobs or tokens in `ci`, `dev-user` can still read pods, and `pipeline-user` is unchanged.

## Step 1: Find the binding

```sh
kubectl -n ci get rolebindings -o wide
```

The binding `team-edit` gives the cluster role `edit` to the user `dev-user`.

## Step 2: Confirm the problem

```sh
kubectl auth can-i create pods -n ci --as dev-user
kubectl auth can-i create serviceaccounts/token -n ci --as dev-user
```

Both answer `yes`. Either one is enough to sign as `release-bot`.

## Step 3: Replace the binding with a read-only one

The field `roleRef` of a binding cannot be changed, so delete the binding and create a new one for the cluster role `view`:

```sh
kubectl -n ci delete rolebinding team-edit
kubectl -n ci create rolebinding team-view --clusterrole=view --user=dev-user
```

## Step 4: Check both users

```sh
kubectl auth can-i create pods -n ci --as dev-user
kubectl auth can-i create serviceaccounts/token -n ci --as dev-user
kubectl auth can-i get pods -n ci --as dev-user
kubectl auth can-i create pods -n ci --as pipeline-user
```

The first two answer `no`, the last two `yes`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete `pipeline-edit` as well | The real pipeline can no longer sign |
| Delete the service account `release-bot` | Removes the signer instead of the access |
| Try `kubectl edit rolebinding` to change the role | The API server rejects a change of `roleRef` |

## Common mistakes

- Removing only the pod permission and forgetting `serviceaccounts/token`.
- Checking with your own administrator account instead of `--as dev-user`.
