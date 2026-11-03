# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Workload identity

## Scenario

The release pipeline signs images in the namespace `ci` as the service account `release-bot`. A developer account named `dev-user` was bound to a role in `ci` for an unrelated task. During a review you find that this account can run pods in `ci`, and so it can sign images that verify as `ci/release-bot`. The account `pipeline-user` is the real pipeline and must keep working.

## Your task

1. Find out which role binding in the namespace `ci` gives `dev-user` its rights, and which permissions allow signing.
2. Change the access of `dev-user` so it can only read in `ci`.
3. Check the result for both users with `kubectl auth can-i` and `--as`.

## Constraints

- `dev-user` must keep read access to pods in `ci`.
- Do not change the binding or the rights of `pipeline-user`.
- Do not delete the service account `release-bot` or the namespace `ci`.
- A role binding cannot change its role reference. Replace the binding.

## Done when

- `dev-user` cannot create pods, jobs or `serviceaccounts/token` in `ci`.
- `dev-user` can still get pods in `ci`.
- `pipeline-user` can still create pods and `serviceaccounts/token` in `ci`, and `release-bot` still exists.
