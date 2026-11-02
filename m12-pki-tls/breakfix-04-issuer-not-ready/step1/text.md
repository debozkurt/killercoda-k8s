# Step 1 — Diagnose the shared failure

Read the pattern first. Two failures that start together share a cause.

## The pattern

```bash
kubectl get pods -n media -l app=config-api
kubectl get pods -n app-services -l app=config-client
kubectl get certificate -A
```{{exec}}

Both Pods read ContainerCreating. The leaf `Certificate` objects `config-api-tls` and `config-client-tls` read Ready False. The two CA certificates in `cert-manager` read Ready True. Both leaf certs reference the same issuer.

## Read the CertificateRequest

```bash
kubectl describe certificaterequest -n media
```{{exec}}

In `Conditions:`, read the Message: `Referenced issuer does not have a Ready status condition`. The issuer exists, since the name resolves. The issuer is not Ready, so it signs nothing.

## Read the issuer

```bash
kubectl get clusterissuers
kubectl describe clusterissuer polyphone-ca
```{{exec}}

`polyphone-ca` reads Ready False. In `Status:`, read the Message: `Error getting keypair for CA issuer`, followed by the name of a Secret that does not exist. A CA issuer needs the Secret that holds its signing key pair. List the Secrets in the namespace that holds it:

```bash
kubectl get secrets -n cert-manager
```{{exec}}

The real signing Secret is `polyphone-internal-ca`. The issuer names `polyphone-internal-ca-old`. One wrong `secretName` blocked every leaf cert that the issuer signs.
