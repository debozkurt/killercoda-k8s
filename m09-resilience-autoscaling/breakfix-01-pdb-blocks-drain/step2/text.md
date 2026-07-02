# Step 2 — Fix it and verify

The budget needs headroom: with 2 replicas, `minAvailable: 1` keeps one Pod serving at all times while allowing the other to be evicted. That's `allowedDisruptions = 2 − 1 = 1` — enough to drain one node at a time.

## Lower minAvailable below the replica count

```bash
kubectl patch pdb sip-registrar -n signaling \
  --type merge -p '{"spec":{"minAvailable":1}}'
```{{exec}}

## Verify the budget now has headroom

```bash
kubectl get pdb sip-registrar -n signaling
```{{exec}}

`ALLOWED DISRUPTIONS` is now `1`. Confirm the eviction API agrees — the same call that was refused in step 1 now succeeds (the Deployment immediately schedules a replacement, so you stay at 2 replicas):

```bash
POD=$(kubectl get pod -n signaling -l app=sip-registrar -o jsonpath='{.items[0].metadata.name}')
cat <<EOF > /tmp/evict.json
{"apiVersion":"policy/v1","kind":"Eviction","metadata":{"name":"$POD","namespace":"signaling"}}
EOF
kubectl create --raw "/api/v1/namespaces/signaling/pods/$POD/eviction" -f /tmp/evict.json
kubectl get pods -n signaling -l app=sip-registrar
```{{exec}}

The eviction returns cleanly (no `TooManyRequests`), one Pod cycles, and the Deployment restores `2/2`. A node drain would now proceed one replica at a time. That's exactly what a PDB is for: it doesn't *prevent* disruption, it *paces* it.

## Choosing the number

`minAvailable: 1` is right for a 2-replica service where losing one is acceptable. The considerations for real workloads:

- **`minAvailable` vs `maxUnavailable`.** `maxUnavailable: 1` expresses the same "one at a time" without hardcoding a replica count — better when an HPA changes the replica count under you (a fixed `minAvailable` can silently become "block everything" or "protect nothing" as replicas scale).
- **Never set `minAvailable` equal to (or above) the replica count** — that's this bug: a budget that can never be met.
- **Headroom for the drain to make progress.** The drain evicts, waits for the Deployment to bring a fresh Pod up *elsewhere*, then evicts the next. On a single-node cluster there's nowhere else to go, so a full drain still won't finish — but the budget is no longer the blocker, and that's the concept this scenario teaches.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
