# Step 3 — Selector to EndpointSlice

A Service finds its Pods by **label selector**, exactly the way a ReplicaSet does (M01). The result — the actual backend addresses — lives in a separate object: the **EndpointSlice**. The distinction between "the Service exists" and "the Service has backends" is the single most important diagnostic fact in this module.

## Read the backends behind the Service

```bash
kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker
```{{exec}}

The `ENDPOINTS` column lists an address per endpoint, on the resolved target port. Add `-o yaml` to see each endpoint's `conditions` as well as its address:

```bash
kubectl get endpointslice -n media \
  -l kubernetes.io/service-name=session-broker \
  -o jsonpath='{.items[0].endpoints[*].conditions}'; echo
```{{exec}}

This is the list the Service dataplane forwards across. If it holds no addresses, the Service routes nowhere — no matter how healthy `get svc` looks.

## See where that list comes from: selector meets labels

```bash
kubectl get svc session-broker -n media -o yaml | grep -A1 selector
```{{exec}}

The selector reads `app: session-broker`. Now look at the Pods' labels:

```bash
kubectl get pods -n media -l app=session-broker --show-labels
```{{exec}}

The Pods carry `app=session-broker`, matching the selector — so the endpoints controller writes them into the EndpointSlice. **Only `Ready` Pods are included**: the same readiness gate from M01 doubles as load-balancer membership, so a Pod that fails its readiness probe is pulled from traffic without being killed.

## The instinct to build

`kubectl get svc` proves a Service *exists*. `kubectl get endpointslice` proves it has somewhere to send traffic. When connectivity is broken but the Pods look healthy, the endpoints listing is the first place to look — it's the discriminator the next scenarios turn on.
