# Step 1 — The CRD: a new type in the API

A **CustomResourceDefinition** registers a new resource type with the API server. Once it's `Established`, that type behaves like any built-in.

## The definition

```bash
kubectl get crd | grep polyphone
```{{exec}}

`mediatenants.polyphone.example` — a CRD is itself an object (`kind: CustomResourceDefinition`). Its name is always `<plural>.<group>`. Confirm the API server has fully registered it:

```bash
kubectl get crd mediatenants.polyphone.example -o jsonpath='{.status.conditions[?(@.type=="Established")].status}'; echo
```{{exec}}

`True` — the type is served. Until a CRD is `Established`, `kubectl get <kind>` fails with "the server doesn't have a resource type."

## It's a first-class type now

```bash
kubectl api-resources | grep mediatenant
```{{exec}}

`MediaTenant`, short name `mt`, API group `polyphone.example`, `NAMESPACED true` — it sits in `api-resources` next to Pods and Deployments. The same verbs work on it:

```bash
kubectl explain mediatenant.spec
```{{exec}}

`explain` reads the schema baked into the CRD: `tier` (a string) and `replicas` (an integer). The API server validates every MediaTenant against this schema, exactly as it does a built-in — that's what makes a custom resource first-class, not just a blob of YAML.
