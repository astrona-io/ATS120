# Keyless Signing In GitHub Actions

GitHub Actions is where most open-source images are built, and where most keyless signatures on the internet come from. A workflow job can sign without any secret because GitHub hands it an identity token for the run. This part walks through a complete signing workflow, explains each permission and step, and shows how to verify the signature it produces.

## How a job gets an ID token

GitHub runs an OpenID Connect (OIDC) provider with the issuer URL `https://token.actions.githubusercontent.com`. A job can ask it for an ID token only if the workflow grants the permission `id-token: write`. That permission does not let the job write anything to the repository; it only allows the job to request a token. GitHub then gives the runner two environment variables, `ACTIONS_ID_TOKEN_REQUEST_URL` and `ACTIONS_ID_TOKEN_REQUEST_TOKEN`, and cosign uses them to fetch a token with the audience `sigstore`.

The token's claims describe the run: the repository, the workflow file, the git reference, the commit, the event that triggered it and the runner environment. Fulcio copies them into the certificate, so the signature records exactly which run produced it. No secret is stored in the repository or in the GitHub settings.

## A complete signing workflow

The workflow below builds an image on every tag that starts with `v`, pushes it to the GitHub Container Registry (`ghcr.io`), and signs the pushed digest keylessly. It is a file in a GitHub repository, so a lab cannot run it; read it step by step. If you have a GitHub repository, save this as `.github/workflows/release.yml`:

```yaml
name: release
on:
  push:
    tags: ["v*"]

permissions:
  contents: read

jobs:
  image:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write   # push to ghcr.io
      id-token: write   # request an OIDC token for keyless signing
    steps:
      - uses: actions/checkout@v7.0.1
      - uses: docker/setup-buildx-action@v4.4.1
      - uses: docker/login-action@v4.6.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: build
        uses: docker/build-push-action@v7.4.0
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.ref_name }}
      - uses: sigstore/cosign-installer@v4.1.2
        with:
          cosign-release: v3.1.4
      - name: Sign the pushed digest
        env:
          IMAGE: ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}
        run: cosign sign --yes "$IMAGE"
```

Three choices in it matter. The permissions are set per job and kept to the minimum: `id-token: write` only where signing happens, `packages: write` only for the push. The image is signed by the digest the build step reported, `steps.build.outputs.digest`, not by the tag, so the signature covers exactly what was built. And cosign runs without any key or flag for Fulcio: with no `--key` and no `--signing-config`, cosign v3 uses the public-good Sigstore instance, fetches the job's ID token and signs keylessly. In a real repository, pin each action to its full commit hash instead of a version tag, so a moved tag cannot change what runs.

`secrets.GITHUB_TOKEN` in the login step is the token GitHub creates for every run to call its own APIs, here to push to `ghcr.io`. It is not a signing key, and it expires when the run ends.

## The identity it produces

The certificate for this workflow has the identity `https://github.com/<owner>/<repository>/.github/workflows/release.yml@refs/tags/<tag>`, the URL of the workflow file at the tag it ran for, and the issuer `https://token.actions.githubusercontent.com`. The source repository, the reference, the commit and the trigger are recorded in Fulcio's extensions. A consumer verifies such an image like this, after filling in the placeholders:

```sh
cosign verify ghcr.io/<owner>/<repository>:v1.0.0 \
  --certificate-identity-regexp '^https://github\.com/<owner>/<repository>/\.github/workflows/release\.yml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-github-workflow-repository <owner>/<repository> \
  --certificate-github-workflow-trigger push
```

Replace each `<owner>` and `<repository>` before you run it. The pattern pins the workflow file and the tag prefix, and the flags pin the issuer, the repository and the event that triggered the run.

## Checking a real one

Flux signs its controller images with a workflow like this one. Check the trigger and the reference of the source-controller release from Flux v2.9.6 in a workstation shell; it needs outbound internet:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

```sh
cosign verify ghcr.io/fluxcd/source-controller:v1.9.6 \
  --certificate-identity-regexp='^https://github\.com/fluxcd/' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-github-workflow-repository=fluxcd/source-controller \
  --certificate-github-workflow-ref=refs/tags/v1.9.6 >/dev/null && echo "built from tag v1.9.6"
```

Flux builds each release from its tag, so the check prints `built from tag v1.9.6` when the run for that tag made the signature. Change the reference to `refs/tags/v1.9.5` and run it again: the check fails, because no signature on this image comes from a run for `v1.9.5`. The certificate pins not only who built the image but which release build produced it.

You now know how a GitHub Actions job signs without a secret, which permissions it needs, and which identity and claims a consumer checks. The open question is a pipeline that is not on GitHub: the same pattern inside your own cluster, with a Kubernetes Job.

## Common pitfalls

> [!WARNING]
> - **Granting `id-token: write` to the whole workflow.** Give it only to the job that signs, so other jobs cannot get a signing identity.
> - **Signing the tag after the push.** Another push could have moved it. Sign the digest the build step reported.
> - **Reusable workflows.** When a release calls a reusable workflow, the identity is that workflow's URL. Check the source repository claim too.
> - **Running untrusted pull request code with `id-token: write`.** A job that runs code from a fork with that permission can sign as your repository's workflow.
