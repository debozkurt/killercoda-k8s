# Step 4 — Selector to EndpointSlice

A Service finds its Pods by **label selector**, exactly the way a ReplicaSet does (M01). The result — the actual backend addresses — lives in a separate object: the **EndpointSlice**. The distinction between "the Service exists" and "the Service has backends" is the single most important diagnostic fact in this module.

## Read the backends behind the Service

```bash
kubectl get endpointslice -n media -l kubernetes.io/service-name=session-broker
```{{exec}}

The `ENDPOINTS` column lists an address per endpoint, and `PORTS` the port they were resolved to. This is the list the Service dataplane forwards across. If it holds no addresses, the Service routes nowhere — no matter how healthy `get svc` looks.

`describe` gives the same slice with each endpoint's readiness spelled out:

```bash
kubectl describe endpointslice -n media -l kubernetes.io/service-name=session-broker
```{{exec}}

Under `Endpoints:`, each entry has a `Conditions:` block reading `Ready: true`. That flag is what the dataplane filters on.

## See where that list comes from: selector meets labels

```bash
kubectl describe svc session-broker -n media
```{{exec}}

Two lines to read. `Selector: app=session-broker` is the query. `Endpoints:` is its answer, the same addresses you just listed — one command showing both sides. Now look at the Pods the selector is querying:

```bash
kubectl get pods -n media --show-labels
```{{exec}}

The `session-broker` Pods carry `app=session-broker`, matching the selector — so the endpoints controller writes them into the EndpointSlice. **Only `Ready` Pods are included**: the same readiness gate from M01 doubles as load-balancer membership, so a Pod that fails its readiness probe is pulled from traffic without being killed.

## The instinct to build

`kubectl get svc` proves a Service *exists*. `kubectl describe svc` — or `get endpointslice` — proves it has somewhere to send traffic. When connectivity is broken but the Pods look healthy, that is the first place to look.
