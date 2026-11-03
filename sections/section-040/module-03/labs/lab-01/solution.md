# Solution: Find Why Three Signers Failed

Work the task yourself first. Running `astrona submit -c sections/section-040/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks three things: the report is right, the Jobs still exist, and nothing signed the digest.

## Step 1: Look at all three Jobs

```sh
kubectl -n ci get jobs
kubectl -n ci get pods
```

Two Jobs have pods. One Job has none.

## Step 2: The Job without a pod

```sh
kubectl -n ci describe job sign-b
```

The events say that the pod could not be created because the service account `missing-bot` was not found. The cause is `service-account`.

## Step 3: The two Jobs with pods

```sh
kubectl -n ci logs job/sign-a
kubectl -n ci logs job/sign-c
```

The log of `sign-a` shows that Fulcio refused the token. The Job asked for a token with the audience `fulcio`, and this Fulcio requires `sigstore`. The cause is `audience`. You can see the audience in the Job spec with `kubectl -n ci get job sign-a -o yaml`.

The log of `sign-c` shows that the registry has no manifest for the digest in the image reference. The cause is `image`.

## Step 4: Write the report

```sh
kubectl -n ci create configmap failure-report \
  --from-literal=jobA=audience --from-literal=jobB=service-account --from-literal=jobC=image
```

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete and re-create the Jobs with fixes | The grader expects the original Jobs |
| Sign the digest as another service account | The grader finds the new signature |
| Guess from the Job names | The causes are not in the order of the letters you expect |

## Common mistakes

- Looking for a log in the Job without a pod.
- Reading `ci-builder` as the problem in all three Jobs.
