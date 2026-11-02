# Step 1 — Diagnose the stuck server

A Pod stuck in `ContainerCreating` waits for something it needs. Follow what it waits for.

## The Pod waits, it does not crash

```bash
kubectl get pods -n media -l app=config-api
kubectl describe pod -n media -l app=config-api
```{{exec}}

The Pod reads ContainerCreating, 0/1. In the `describe` output, read the `Events:` at the bottom. A `FailedMount` event says `secret "config-api-tls" not found`. The Pod mounts a Secret that does not exist. A cert-manager Secret comes from a `Certificate`.

## Climb to the Certificate

```bash
kubectl get certificate config-api-tls -n media
kubectl describe certificate config-api-tls -n media
```{{exec}}

Ready is False. The `Events:` show that cert-manager started an issuance because the Secret does not exist, then created a CertificateRequest. The **CertificateRequest** is the object that asks an issuer to sign one key pair. It holds the reason for a failure.

## Read the CertificateRequest

```bash
kubectl describe certificaterequest -n media
```{{exec}}

In `Conditions:`, read the Message: `Referenced "ClusterIssuer" not found`, followed by the name `polyphone-ca-typo`. The `Certificate` names an issuer that does not exist. Compare with the real issuers:

```bash
kubectl get clusterissuers
```{{exec}}

The internal CA issuer is `polyphone-ca`.
