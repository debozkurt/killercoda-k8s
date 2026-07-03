# Step 2 — Fix it and verify

`platinum` isn't a tier this platform offers. Confirm with the team which real tier they meant — assume `gold` — set it, and re-apply. Once the custom resource is valid, the API server accepts it and the operator does the rest.

## Correct the tier and apply

```bash
sed -i 's/tier: platinum/tier: gold/' /root/vega-tenant.yaml
kubectl apply -f /root/vega-tenant.yaml
```{{exec}}

`mediatenant.polyphone.example/vega created`. It passes the schema now, so it's persisted — and the operator, which watches for MediaTenants, picks it up on its next pass.

Prefer to edit by hand? `vi /root/vega-tenant.yaml` and change `tier: platinum` to one of `gold`, `silver`, `bronze`, then `kubectl apply -f /root/vega-tenant.yaml`.

## Verify vega provisioned

```bash
kubectl get mediatenants -A
```{{exec}}

`vega` now appears alongside `orion` and `lyra`. Give the operator a few seconds, then confirm it built the capacity:

```bash
kubectl get deployment vega-media -n media
kubectl get mediatenant vega -n media -o jsonpath='{.status.phase}'; echo
```{{exec}}

`vega-media` exists (3 replicas, the value from the manifest), and the tenant's `.status.phase` moves to `Ready`. A valid custom resource was all the operator needed — the schema was the gate, not the operator. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
