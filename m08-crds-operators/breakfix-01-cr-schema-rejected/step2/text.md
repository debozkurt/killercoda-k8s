# Step 2 — Fix it and verify

`platinum` is not a tier the platform offers. Assume the team meant `gold`. Set it, and apply again.

## Correct the tier

```bash
sed -i 's/tier: platinum/tier: gold/' /root/vega-tenant.yaml
kubectl apply -f /root/vega-tenant.yaml
```{{exec}}

`mediatenant.polyphone.example/vega created`. The object passes the schema, so the API server stores it. The operator finds it on its next pass.

## Verify

```bash
kubectl get mediatenants -A
sleep 15
kubectl get deployment vega-media -n media
```{{exec}}

`vega` appears next to `orion` and `lyra`, and the operator creates `vega-media` with 3 replicas. A valid resource was all the operator needed. The schema was the gate.
