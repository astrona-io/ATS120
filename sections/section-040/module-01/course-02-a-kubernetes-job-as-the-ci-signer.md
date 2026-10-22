# A Kubernetes Job As The CI Signer

Not every pipeline runs on GitHub. Tekton, Argo Workflows and plain Kubernetes Jobs all run build and release steps as pods in a cluster. The keyless pattern carries over unchanged: the pod's service account is the pipeline identity, a projected token is the ambient credential, and Fulcio turns it into a certificate. This part builds a release Job that signs the release digest and verifies its own signature in the same run, with no key anywhere.

## Sign, then verify in the same run

A pipeline that signs and never checks the result can fail silently: a wrong service account, a wrong audience or a wrong digest all produce a signature nobody asked for, or none at all. So the release Job has two steps. An init container signs; the main container verifies the signature with the exact identity the deployment check will demand. If verification fails, the Job fails, and the pipeline stops before anything ships.

```mermaid
flowchart LR
    R["release-info: digest"] -->|"IMAGE"| S["init: cosign sign"]
    S -->|"signature"| V["main: cosign verify"]
    V -->|"identity ci/ci-builder"| D["Job complete"]
```

The diagram shows the Job reading the digest once, signing it in the init container, and completing only if the main container verifies the signature for `ci/ci-builder`.

The two steps need different things. The signing step needs the token and the signing configuration. The verifying step needs only the trusted root and the issuer; it does not get the token, because verifying needs no identity. Giving each container only what it uses keeps the token out of the verifier.

## The release Job

Both containers use the cosign image. The image to sign comes from `release-info`, and the issuer for the verify step comes from the ConfigMap `sigstore-trust`, so nothing is typed by hand.

<!-- astrona:playground:renew -->

Save this as `job-ci-sign.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ci-sign
  namespace: ci
spec:
  backoffLimit: 0
  template:
    spec:
      serviceAccountName: ci-builder
      restartPolicy: Never
      initContainers:
        - name: sign
          image: ghcr.io/sigstore/cosign/cosign:v3.1.4
          args:
            - sign
            - --yes
            - --allow-http-registry
            - --identity-token=/var/run/sigstore/token
            - --signing-config=/etc/sigstore/signing-config.json
            - --trusted-root=/etc/sigstore/trusted-root.json
            - $(IMAGE)
          env:
            - name: IMAGE
              valueFrom:
                configMapKeyRef:
                  name: release-info
                  key: image
            - name: HOME
              value: /tmp
          volumeMounts:
            - name: sigstore-trust
              mountPath: /etc/sigstore
              readOnly: true
            - name: sigstore-token
              mountPath: /var/run/sigstore
              readOnly: true
            - name: tmp
              mountPath: /tmp
      containers:
        - name: verify
          image: ghcr.io/sigstore/cosign/cosign:v3.1.4
          args:
            - verify
            - --allow-http-registry
            - --trusted-root=/etc/sigstore/trusted-root.json
            - --certificate-identity=https://kubernetes.io/namespaces/ci/serviceaccounts/ci-builder
            - --certificate-oidc-issuer=$(OIDC_ISSUER)
            - $(IMAGE)
          env:
            - name: IMAGE
              valueFrom:
                configMapKeyRef:
                  name: release-info
                  key: image
            - name: OIDC_ISSUER
              valueFrom:
                configMapKeyRef:
                  name: sigstore-trust
                  key: oidc-issuer
            - name: HOME
              value: /tmp
          volumeMounts:
            - name: sigstore-trust
              mountPath: /etc/sigstore
              readOnly: true
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: sigstore-trust
          configMap:
            name: sigstore-trust
        - name: sigstore-token
          projected:
            sources:
              - serviceAccountToken:
                  path: token
                  audience: sigstore
                  expirationSeconds: 600
        - name: tmp
          emptyDir: {}
```

Apply it:

```sh
kubectl apply -f job-ci-sign.yaml
```

Then check the result:

```sh
kubectl -n ci wait --for=condition=complete job/ci-sign --timeout=240s
kubectl -n ci logs job/ci-sign -c sign
kubectl -n ci logs job/ci-sign -c verify
```

The Job completes. The `sign` log shows the certificate request, the log upload and the push. The `verify` log lists the checks cosign made and ends with the JSON of the accepted signature. Note what the Job does not contain: no Secret, no key file, no password. The only credential is the projected token, which expires after ten minutes.

## Proving the pipeline identity

From the deployment side, check that the release digest carries the pipeline's identity, and that it is not just "signed":

```sh
IMAGE="$(kubectl -n ci get configmap release-info -o jsonpath='{.data.image}')"
for sa in ci/ci-builder workstation/workstation; do
  ns="${sa%/*}"; name="${sa#*/}"
  kubectl -n workstation exec deploy/workstation -- sh -c "cosign verify --allow-http-registry \
    --trusted-root /etc/sigstore/trusted-root.json \
    --certificate-identity https://kubernetes.io/namespaces/$ns/serviceaccounts/$name \
    --certificate-oidc-issuer \"\$(cat /etc/sigstore/oidc-issuer)\" $IMAGE >/dev/null 2>&1" \
    && echo "$sa: signed" || echo "$sa: not signed"
done
```

`ci/ci-builder: signed` and `workstation/workstation: not signed`, unless you also signed from the workstation earlier. The deployment check only ever asks for `ci/ci-builder`.

You can now build a CI signer that signs the recorded digest as its own identity, verifies the result in the same run and holds no key. The open question is the one most teams actually face: an existing pipeline that already signs with a key, and how to move it to keyless without breaking the verifiers.

## Common pitfalls

> [!WARNING]
> - **Signing without verifying.** A Job can succeed while signing as the wrong identity. Verify in the same run with the identity the deployment demands.
> - **Giving the verify step the token.** Verifying needs no identity; mount the token only in the signing step.
> - **Reading the digest twice from different places.** Take the digest from one source, `release-info` here, so the signed and the verified image are the same.
> - **Keeping the old key "for safety".** A key that still exists can still sign. Remove it once the keyless signer works.

## Your mission: Sign And Verify In A CI Job

You can now build a release Job that signs the recorded digest as `ci/ci-builder` and verifies it in the same run. The graded lab asks you to build exactly that Job, with no Secret, and grades the identity of the resulting signature.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-120-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS120.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-120-lab-040-01
astrona start ats-120-playground-040-01
```
