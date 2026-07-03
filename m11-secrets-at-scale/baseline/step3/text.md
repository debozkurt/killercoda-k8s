# Step 3 — The operator reconciling: reading sync status

The operator is a controller, so it reports on the channel M08 taught: the object's `.status` and its own logs. When a synced Secret goes wrong later, this is where you look first — not the consumer Pod.

## The operator is running

```bash
kubectl get pods -n secrets-system
```{{exec}}

`secret-operator` `Running`, 0 restarts. But "Running" only means the process is alive — a controller's real state is what it reconciled, in `.status`.

## The sync result in .status

```bash
kubectl get secretsync db-credentials -n provisioning -o jsonpath='{.status}'; echo
```{{exec}}

`ready: "True"`, `reason: Synced`, and `syncedKeys: DB_PASSWORD` — the operator read the store, resolved every named key, and materialized the target. That's the per-object receipt of a healthy sync.

## The operator's logs

```bash
kubectl logs deployment/secret-operator -n secrets-system --tail=8
```{{exec}}

A `Synced -> <ns>/<target>` line per SecretSync, once per pass. The loop is level-triggered (M08): every ~10 seconds it re-reads the store and re-materializes each Secret, so a change in the store propagates on the next pass without anyone restarting the operator. These two signals — `.status` and the logs — are the pipeline's health surface.
