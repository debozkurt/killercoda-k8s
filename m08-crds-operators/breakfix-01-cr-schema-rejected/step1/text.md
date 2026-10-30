# Step 1 — Diagnose the rejected resource

The fault is an absence: `vega` does not exist. Confirm that, then apply the manifest and let the API server explain.

## vega is not there

```bash
kubectl get mediatenants -A
```{{exec}}

Two tenants. The operator provisions what exists, so there is no `vega-media` either. This is not a reconcile problem. The custom resource was never stored.

## Apply the manifest, read the error

```bash
kubectl apply -f /root/vega-tenant.yaml
```{{exec}}

The API server answers with one line that names the field, the bad value and the allowed values:

```
The MediaTenant "vega" is invalid: spec.tier: Unsupported value: "platinum": supported values: "gold", "silver", "bronze"
```

That is **admission validation**. The CRD carries an OpenAPI schema, and the API server checks every custom resource against it before it stores the object. Nothing was written, so the operator never ran for `vega`.

## Read the schema you must satisfy

```bash
kubectl explain mediatenant.spec.tier
cat /root/vega-tenant.yaml
```{{exec}}

`explain` reads the same schema back and lists the allowed values. The manifest asks for `platinum`, which is not in the list.
