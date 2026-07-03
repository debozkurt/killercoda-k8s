# Step 1 — Diagnose the rejected resource

The bug is an *absence*: `vega` doesn't exist. Confirm that, then apply its manifest and let the API server tell you why.

## vega isn't there

```bash
kubectl get mediatenants -A
```{{exec}}

Only `orion` and `lyra`. The operator provisions what exists, and `vega` doesn't — so no `vega-media` Deployment either. This isn't a reconcile problem; the resource was never created.

## Apply the manifest and read the error

```bash
kubectl apply -f /root/vega-tenant.yaml
```{{exec}}

The API server rejects it:

```
The MediaTenant "vega" is invalid: spec.tier: Unsupported value: "platinum": supported values: "gold", "silver", "bronze"
```

That's **admission validation**. The CRD carries an OpenAPI schema, and the API server checks every custom resource against it before persisting — a wrong enum value is refused exactly as a malformed built-in would be. Nothing was written, so nothing downstream (the operator, a child Deployment) ever happened.

## Read the schema you have to satisfy

```bash
kubectl explain mediatenant.spec.tier
```{{exec}}

```bash
kubectl get crd mediatenants.polyphone.example \
  -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.tier.enum}'; echo
```{{exec}}

The allowed tiers are `["gold","silver","bronze"]`. The manifest asked for `platinum` — not in the set. See the offending line:

```bash
grep tier /root/vega-tenant.yaml
```{{exec}}

`tier: platinum`. The fix is to make the resource conform to the schema.
