# Step 1 — Diagnose the store-wide outage

Two consumers down in two namespaces is a signal in itself. Read the syncs first — a fan-out that all names one store is a store problem — then prove the operator's identity lost access.

## The fan-out points at the store

```bash
kubectl get secretsync -A
```{{exec}}

*Both* syncs read `READY False`, `REASON StoreNotReady` — not `SyncError` on one, but the same store-level failure on every sync. When they all fail identically, don't open two investigations; look at what they share. Read the message:

```bash
kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.status.message}'; echo
```{{exec}}

`cannot read backing store secrets-source/vault-backend`. The operator can't read the store — so nothing downstream can be built. Confirm no targets exist:

```bash
kubectl get secrets -A -l managed-by=secret-operator
```{{exec}}

None — the pipeline produced nothing.

## The operator is Running — so this is access, not a crash

```bash
kubectl get pods -n secrets-system
```{{exec}}

`secret-operator` `Running`, 0 restarts. A controller that's alive but produces nothing points at what it's *allowed* to do (M08). The store itself is fine — the store's *identity* isn't. Ask the API server directly, as the operator (M10):

```bash
kubectl auth can-i get secrets -n secrets-source \
  --as=system:serviceaccount:secrets-system:secret-operator
```{{exec}}

`no`. The operator's ServiceAccount can't read secrets in `secrets-source`. Its store-read comes from one RoleBinding — read it:

```bash
kubectl get rolebinding secret-operator-store -n secrets-source -o jsonpath='{.subjects}'; echo
```{{exec}}

The subject is `secret-operator-ro` — a ServiceAccount that doesn't exist. The binding grants store-read to the wrong identity, so the operator (`secret-operator`) got nothing. One mis-subjected RoleBinding took the whole pipeline offline.
