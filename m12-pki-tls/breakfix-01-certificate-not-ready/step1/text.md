# Step 1 — Diagnose the stuck server

A Pod that won't leave `ContainerCreating` is almost never the Pod's fault — something it *needs* isn't there yet. Follow what it's waiting on.

## The Pod is stuck, not crashing

```bash
kubectl get pods -n media -l app=config-api
```{{exec}}

`ContainerCreating`, `0/1`, no restarts. It isn't crashlooping (that would be a bad image or command) — it can't even start. Ask why:

```bash
kubectl describe pod -n media -l app=config-api | sed -n '/Events:/,$p'
```{{exec}}

```text
Warning  FailedMount  ...  MountVolume.SetUp failed for volume "tls" :
                           secret "config-api-tls" not found
```

The Pod mounts Secret `config-api-tls` to serve HTTPS, and that Secret **doesn't exist**. Don't chase the Pod — chase the Secret. And a cert-manager Secret is written by a `Certificate`.

## Climb to the Certificate

```bash
kubectl get certificate config-api-tls -n media
```{{exec}}

`READY=False`. That's the whole story: the cert never issued, so its Secret was never written, so the Pod can't mount it. Now find *why* it didn't issue — the reason lives one rung down, on the `CertificateRequest`:

```bash
kubectl describe certificate config-api-tls -n media | sed -n '/Status:/,$p'
kubectl describe certificaterequest -n media -l cert-manager.io/certificate-name=config-api-tls | sed -n '/Status:/,$p'
```{{exec}}

```text
Message:  Referenced "ClusterIssuer" not found: clusterissuer.cert-manager.io "polyphone-ca-typo" not found
```

There it is. The `Certificate`'s `issuerRef` names `polyphone-ca-typo`, an issuer that doesn't exist — so cert-manager has nothing to sign with. Confirm the real issuer's name:

```bash
kubectl get clusterissuers
```{{exec}}

The internal CA issuer is `polyphone-ca` (no `-typo`). Root cause: the `Certificate` points at a non-existent issuer. On to the fix.
