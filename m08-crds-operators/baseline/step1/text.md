# Step 1 — The CRD: a new type in the API

A **CustomResourceDefinition** (CRD) registers a new resource type with the API server. Once the type is `Established`, it behaves like a built-in.

## The definition

```bash
kubectl get crd | grep polyphone
```{{exec}}

`mediatenants.polyphone.example`. A CRD is an object too (`kind: CustomResourceDefinition`), and its name is always `<plural>.<group>`. Read its conditions:

```bash
kubectl describe crd mediatenants.polyphone.example
```{{exec}}

Find the `Established` condition under `Status:`. Its `Status` is `True`: the API server serves the type. Before that, `kubectl get <kind>` fails with "the server doesn't have a resource type". Under `Versions:` read the `Name:`, `Served:` and `Storage:` lines. One version, `v1`, is served and stored.

## The type behaves like a built-in

```bash
kubectl api-resources | grep mediatenant
```{{exec}}

`MediaTenant` has the short name `mt`, the group `polyphone.example`, and NAMESPACED true. It sits in the list next to Pods and Deployments. The same verbs work on it:

```bash
kubectl explain mediatenant.spec
```{{exec}}

`explain` reads the schema stored in the CRD: `tier` is a string and `replicas` is an integer. The API server validates every MediaTenant against that schema, as it does for a built-in. Step 2 shows the result.
