# Other CI Providers And Issuers

Fulcio does not know GitHub, GitLab or Kubernetes by name. It knows a list of **OIDC issuers** it is configured to trust, and for each issuer a rule that turns the token's claims into the identity written in the certificate. Which providers a Fulcio accepts is configuration. This module shows where that configuration lives, how GitLab CI signs, and how to pick the right verification flags for any provider.

The module has four parts. **How Fulcio Decides Which Issuers To Trust** reads the configuration of the private stack. **GitLab CI Identities** signs from a GitLab pipeline. **Reading The Issuer And Subject Of Any Signature** finds the values to pin when you meet an unknown signature. **Choosing The Flags For Each Provider** collects the rules in one table. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Explain what a Fulcio issuer entry contains and what the issuer type does.
- Read the issuers a Fulcio trusts from its configuration endpoint.
- Write a GitLab CI job that gets an ID token and signs with it.
- Name the identity and issuer a GitLab signature carries.
- Discover the identity and issuer of an unknown signature, then pin them.
- Choose the verification flags for GitHub, GitLab, Kubernetes and email identities.

## Before you start

You need to know the keyless flow, the identity in a certificate and exact verification. No GitLab account is needed. The GitLab parts explain the pipeline file; the lab runs in the cluster.

Your playground is the same private Sigstore stack. The ConfigMap `sigstore-trust` holds the cluster's issuer in the key `oidc-issuer`. The service account `ci-builder` in the namespace `ci` has signed nothing yet.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
