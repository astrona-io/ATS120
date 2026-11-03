# Verifying A CI Signature At Deploy

The signing side is half of the work. The deploy step must demand that the signature came from the right pipeline, and not from any pipeline. This part writes the verification flags for both kinds of CI signature used in this module.

## A GitHub Actions signature

The certificate of a GitHub Actions job holds the workflow identity as its subject and the GitHub claims as extensions. The issuer is `https://token.actions.githubusercontent.com`. A strict check pins them all. The values below are examples; replace the owner, the repository and the workflow:

```sh
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity https://github.com/OWNER/REPOSITORY/.github/workflows/release.yml@refs/heads/main \
  OWNER-IMAGE@sha256:DIGEST
```

The identity includes the workflow file and the ref. A signature from another workflow, or from a pull request branch, has another identity and fails. When releases come from tags, a regular expression is needed for the ref. Anchor it:

```sh
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github\.com/OWNER/REPOSITORY/\.github/workflows/release\.yml@refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' \
  OWNER-IMAGE@sha256:DIGEST
```

cosign has flags for the GitHub extensions too: `--certificate-github-workflow-repository`, `--certificate-github-workflow-name`, `--certificate-github-workflow-ref`, `--certificate-github-workflow-sha` and `--certificate-github-workflow-trigger`. Use them to add conditions on top of the identity, for example the trigger.

## A Kubernetes Job signature

The identity is the service account and the issuer is the cluster's. This is the check:

<!-- astrona:playground:renew -->

Read the recorded image on your machine and pass it into the workstation:

```sh
IMAGE="$(kubectl -n ci get configmap release-info -o jsonpath='{.data.image}')"
kubectl -n workstation exec deploy/workstation -- sh -c "
  cosign verify --allow-http-registry --trusted-root /etc/sigstore/trusted-root.json \
    --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder \
    --certificate-oidc-issuer \"\$(cat /etc/sigstore/oidc-issuer)\" \
    $IMAGE >/dev/null && echo ok"
```

It prints `ok` once the signing Job has signed the digest.

## Where the verification belongs

The pipeline that signs should not be the only place that verifies. Verify again where the image is used: in the deploy step, or in an admission policy. A check at the place of use catches an image that never passed through the pipeline.

## Common pitfalls

> [!WARNING]
> - **Verifying in the same job and stopping there.** The signing job proves that it worked. The deploy step must prove the image is acceptable.
> - **An unanchored expression for tags.** Without `^` and `$`, a longer string that contains the pattern passes.
> - **Dropping the issuer.** An identity string alone can be forged by a provider that issues it. Always pin the issuer.
