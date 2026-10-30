# Step 1 — Diagnose the blocked eviction

The workload is healthy, so read the budget that guards it.

## Read the budget

```bash
kubectl get pods -n signaling -l app=sip-registrar
kubectl get pdb -n signaling
```{{exec}}

Both Pods are Ready. `sip-registrar` shows MIN AVAILABLE 2 and ALLOWED DISRUPTIONS 0. The budget permits no voluntary removal, and a drain is a series of removals.

```bash
kubectl describe pdb sip-registrar -n signaling
```{{exec}}

Read `Min available:`, then the `Status:` block: `Allowed disruptions:`, `Current:`, `Desired:`. Current is 2 and desired is 2, so allowed disruptions is 2 − 2 = 0. Desired comes straight from Min available. A floor equal to the replica count can never allow a disruption.

## See the refusal

`kubectl drain` calls the eviction API. Call it directly on one Pod. This is safe: the call is refused, and nothing is cordoned.

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

A drain retries that refusal for every replica until the budget opens. Next: open it.
