# Signing A Digest The Safe Way

A signing Job should sign exactly the content that was built and tested, and nothing a later push could change. This part shows how a release step gets its digest, why the Job reads it from recorded data and not from a moving tag, and how to check that the Job signed that digest and no other.

## Where the digest comes from

A build step knows the digest at the moment it pushes the image. That value is the one to record. In the playground it is recorded in the ConfigMap `release-info` in the namespace `ci`, key `image`, as a full reference with the digest. Print it:

```sh
kubectl -n ci get configmap release-info -o jsonpath='{.data.image}'
```

The signing Job takes this value through an environment variable. It never resolves a tag on its own. Between "the build finished" and "the Job started", someone could push another image to the tag `6.15.0`, and a Job that resolved the tag would sign that other image.

<!-- astrona:playground:renew -->

See the difference in the workstation. Resolve the tag twice, once now and once from the record:

```sh
kubectl -n workstation exec deploy/workstation -- regctl image digest registry.localtest.me:5001/inventory/podinfo:6.15.0
kubectl -n ci get configmap release-info -o jsonpath='{.data.image}'
```

While nothing was pushed, both name the same content. The record is the one that stays correct after a push.

## What cosign does with a tag

If you pass a tag to `cosign sign`, cosign resolves it to a digest, prints a warning and signs the digest. The signature still covers a digest, but you did not choose which one. In a pipeline, treat the warning as an error: pass a reference of the form `repository@sha256:<hash>`.

## Checking that the Job signed the recorded digest

After the Job `sign-release` has run, verify the recorded reference and not the tag:

```sh
kubectl -n workstation exec deploy/workstation -- sh -c '
  cosign verify --allow-http-registry --trusted-root /etc/sigstore/trusted-root.json \
    --certificate-identity https://kubernetes.io/namespaces/ci/serviceaccounts/release-bot \
    --certificate-oidc-issuer "$(cat /etc/sigstore/oidc-issuer)" \
    '"$(kubectl -n ci get configmap release-info -o jsonpath='{.data.image}')"' >/dev/null && echo "recorded digest is signed"'
```

The outer command reads the record on your machine, and the inner shell verifies it in the workstation. If the Job signed another digest, this command fails, even though an image with a signature exists.

## Common pitfalls

> [!WARNING]
> - **Signing `latest` or any other tag.** The tag moves; the signature stays on the old digest, and nobody notices.
> - **Recording the digest after a long delay.** Record it in the build step that pushed the image.
> - **Verifying the tag after signing.** A verification of a tag proves nothing about the digest a deployment will pull. Verify the digest.
