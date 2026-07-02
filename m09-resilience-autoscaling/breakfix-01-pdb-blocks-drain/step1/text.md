# Step 1 — Diagnose the blocked eviction

The workload is healthy, so don't look at the Pods — look at the budget that guards them.

## Read the disruption budget

```bash
kubectl get pdb -n signaling
```{{exec}}

`sip-registrar` shows `MIN AVAILABLE 2` and, crucially, `ALLOWED DISRUPTIONS 0`. That zero is the whole problem: the budget permits *no* voluntary disruptions, so the eviction API will refuse to remove any replica — and a drain is nothing but a series of evictions.

## See the refusal for yourself

`kubectl drain` uses the eviction API under the hood. You can hit that API directly for one Pod and watch it get rejected — safely, without cordoning the node:

```bash
POD=$(kubectl get pod -n signaling -l app=sip-registrar -o jsonpath='{.items[0].metadata.name}')
cat <<EOF > /tmp/evict.json
{"apiVersion":"policy/v1","kind":"Eviction","metadata":{"name":"$POD","namespace":"signaling"}}
EOF
kubectl create --raw "/api/v1/namespaces/signaling/pods/$POD/eviction" -f /tmp/evict.json
```{{exec}}

```text
Error from server (TooManyRequests): Cannot evict pod as it would violate the pod's disruption budget.
```

That's the exact error a drain would hang on, for every replica, forever. The Pod is *not* evicted — the budget protected it.

## Read the math

```bash
kubectl describe pdb sip-registrar -n signaling
```{{exec}}

The `Status`: `Current Healthy 2`, `Desired Healthy 2`, `Allowed Disruptions 0`. The rule is `allowedDisruptions = currentHealthy − desiredHealthy`, and `2 − 2 = 0`. `Desired Healthy` comes straight from the budget's `minAvailable`:

```bash
kubectl get pdb sip-registrar -n signaling \
  -o jsonpath='{.spec.minAvailable}'; echo
```{{exec}}

`minAvailable: 2` — equal to the replica count. A budget that demands *all* replicas stay available can never permit removing one; it's mathematically unsatisfiable for any disruption. The fix is to leave headroom. On to it.
