# Solution: Tighten A Verification Script

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader runs your script on all three images and expects `6.15.0` to pass and the other two to fail. It also checks that the issuer is pinned and that no `--insecure` flag is used.

## Step 1: Read the current script

```sh
kubectl -n workstation get configmap verify-release -o jsonpath='{.data.verify-release\.sh}'
```

The script verifies with `--certificate-identity-regexp '.*release-bot'` and `--certificate-oidc-issuer-regexp '.*'`. The identity pattern matches any URI ending in `release-bot`, from any namespace, and the issuer pattern accepts every issuer.

## Step 2: See what it accepts

Copy the script into the workstation and run it on each image:

```sh
kubectl -n workstation get configmap verify-release -o jsonpath='{.data.verify-release\.sh}' > verify-release.sh
kubectl -n workstation exec -i deploy/workstation -- sh -c 'cat > /tmp/verify-release.sh' < verify-release.sh
for tag in 6.15.0 6.15.0-rc1 6.15.0-hotfix; do
  kubectl -n workstation exec deploy/workstation -- \
    sh /tmp/verify-release.sh "registry.localtest.me:5001/inventory/podinfo:$tag" >/dev/null 2>&1 \
    && echo "$tag: accepted" || echo "$tag: rejected"
done
```

`6.15.0` and `6.15.0-rc1` are accepted; `6.15.0-hotfix` is rejected, because the workstation identity does not end in `release-bot`.

## Step 3: Write the strict script

Save this as `verify-release.sh`:

```sh
#!/bin/sh
# verify-release.sh IMAGE: exits 0 only when IMAGE was signed by the service
# account release-bot in the namespace ci, through this cluster's issuer.
IMAGE="$1"
exec cosign verify \
  --trusted-root /etc/sigstore/trusted-root.json \
  --allow-http-registry \
  --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot \
  --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
  "$IMAGE"
```

It names the exact identity and reads the exact issuer from the trust files, so it accepts nothing else.

## Step 4: Store it in the ConfigMap

```sh
kubectl -n workstation create configmap verify-release --from-file=verify-release.sh \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Step 5: Run it on all three images

```sh
kubectl -n workstation exec -i deploy/workstation -- sh -c 'cat > /tmp/verify-release.sh' < verify-release.sh
for tag in 6.15.0 6.15.0-rc1 6.15.0-hotfix; do
  kubectl -n workstation exec deploy/workstation -- \
    sh /tmp/verify-release.sh "registry.localtest.me:5001/inventory/podinfo:$tag" >/dev/null 2>&1 \
    && echo "$tag: accepted" || echo "$tag: rejected"
done
astrona submit -c sections/section-030/module-01/labs/lab-01
```

Only `6.15.0` is accepted.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `--certificate-identity-regexp 'ci.*release-bot'` | Unanchored: it still matches other URIs that contain both parts |
| Keep `--certificate-oidc-issuer-regexp '.*'` | Passes the tests here, and accepts any issuer Fulcio trusts; the grader rejects it |
| Delete the `6.15.0-rc1` signature | Hides the symptom; the script still accepts any namespace's release bot |

## Common mistakes

- Writing the issuer into the script by hand with a typo. Reading it from `/etc/sigstore/oidc-issuer` avoids that.
- Using `return` instead of `exec` or `exit`, so the script's exit code is not cosign's.
