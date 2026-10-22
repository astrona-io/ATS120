# Solution: Verify Which Repository Built A Public Image

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader runs your script on source-controller v1.9.6 (must pass) and kustomize-controller v1.9.6 (must fail), and checks that the GitHub Actions issuer is pinned.

## Step 1: See why the organisation check is too wide

Open a shell in the workstation and run the colleague's check on both images:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
for image in source-controller kustomize-controller; do
  cosign verify "ghcr.io/fluxcd/$image:v1.9.6" \
    --certificate-identity-regexp='^https://github\.com/fluxcd/.*$' \
    --certificate-oidc-issuer=https://token.actions.githubusercontent.com >/dev/null 2>&1 \
    && echo "$image: accepted" || echo "$image: rejected"
done
```

Both are accepted: the pattern accepts any workflow in the `fluxcd` organisation.

## Step 2: Read the recorded claims

Let cosign print what it verified for source-controller:

```sh
cosign verify ghcr.io/fluxcd/source-controller:v1.9.6 \
  --certificate-identity-regexp='^https://github\.com/fluxcd/' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com | jq .
```

Among the fields from the certificate you find the source repository `fluxcd/source-controller`, the git reference and the commit. The kustomize-controller certificate records `fluxcd/kustomize-controller` instead. The repository claim is what tells them apart.

## Step 3: Write the script

Save this as `verify-flux.sh`:

```sh
#!/bin/sh
# verify-flux.sh IMAGE: exits 0 only when IMAGE is a source-controller image
# signed in GitHub Actions in the repository fluxcd/source-controller.
exec cosign verify "$1" \
  --certificate-identity-regexp='^https://github\.com/fluxcd/' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-github-workflow-repository=fluxcd/source-controller
```

The identity pattern stays anchored to the organisation, because Flux may sign from a reusable workflow in another `fluxcd` repository. The repository flag narrows the check to one source repository, and the issuer is pinned exactly.

## Step 4: Store and test it

From your machine:

```sh
kubectl -n workstation create configmap verify-flux --from-file=verify-flux.sh \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl -n workstation exec -i deploy/workstation -- sh -c 'cat > /tmp/verify-flux.sh' < verify-flux.sh
for image in source-controller kustomize-controller; do
  kubectl -n workstation exec deploy/workstation -- sh /tmp/verify-flux.sh "ghcr.io/fluxcd/$image:v1.9.6" >/dev/null 2>&1 \
    && echo "$image: accepted" || echo "$image: rejected"
done
astrona submit -c sections/section-030/capstone/labs/lab-01
```

source-controller is accepted, kustomize-controller is rejected.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `--certificate-identity-regexp='^https://github\.com/fluxcd/source-controller/'` only | Breaks if the release runs a reusable workflow from another repository; the repository claim is the reliable check |
| Drop the issuer | Any provider issuing a `https://github.com/...` identity text would pass |
| Pass the private `--trusted-root` | The public image was signed with the public-good instance; verification fails |

## Common mistakes

- Unescaped dots in `github.com`.
- Testing only the image that should pass. A check is proven by what it rejects.
