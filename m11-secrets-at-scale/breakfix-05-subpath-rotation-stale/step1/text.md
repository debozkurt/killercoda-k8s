# Step 1 — Diagnose the stale file

Compare values link by link until two disagree, then read how the last link is wired.

## The pipeline

```bash
kubectl get secretsync -A
kubectl get secret vault-backend -n secrets-source -o jsonpath='{.data.api-token}' | base64 -d; echo
kubectl get secret partner-api -n media -o jsonpath='{.data.API_TOKEN}' | base64 -d; echo
```{{exec}}

Both syncs read Synced. The store and the Secret both print pt_live_rotated_51e0c7, the new token.

## The process

```bash
kubectl exec deploy/partner-connector -n media -- cat /etc/partner/API_TOKEN; echo
```{{exec}}

It prints pt_live_9c2f8a1b7e004d3a, the old token. The Secret and the file disagree.

## How the file is mounted

```bash
kubectl describe pod -n media -l app=partner-connector
```{{exec}}

Read the `Mounts:` line: `/etc/partner/API_TOKEN from partner-api (ro,path="API_TOKEN")`. The `path=` flag means a `subPath` mount: one key of the volume, mounted as a single file. The `Environment:` section is empty, so env is not the cause.

The kubelet updates a Secret volume in place when the Secret changes. It never updates a `subPath` mount. The file keeps the value it had when the container started, the same as an environment variable.
