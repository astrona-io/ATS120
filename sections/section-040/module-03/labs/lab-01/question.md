# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Operating keyless signing

## Scenario

Three signing Jobs in the namespace `ci` were meant to sign the release image. None of them produced a signature. They are named `sign-a`, `sign-b` and `sign-c`, and each failed for a different reason. A colleague wants a short report before anyone changes anything.

## Your task

1. For each Job, find out why it failed. Use the events of the Job, its pods and the logs.
2. Classify each failure with one of these words: `audience` (Fulcio refused the token), `service-account` (the service account of the Job does not exist), `image` (the image reference in the Job does not exist).
3. Create a ConfigMap named `failure-report` in the namespace `ci` with three keys: `jobA`, `jobB` and `jobC`. Each holds the word for `sign-a`, `sign-b` and `sign-c`.

## Constraints

- Do not delete, edit or re-create the three Jobs. The report describes them as they are.
- Do not sign the release digest as another identity to work around the failures.
- Do not use insecure flags.

## Done when

- `failure-report` names the right cause for each of the three Jobs.
- The three Jobs still exist.
- The release digest has no new signature.
