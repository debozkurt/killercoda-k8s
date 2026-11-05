# Step 4 — Reading Envoy configuration with istioctl

The objects you apply are intent. The Envoy configuration that `istiod` compiled and pushed to each sidecar is behavior. `istioctl` reads it.

## Is every sidecar current?

```bash
istioctl proxy-status
```{{exec}}

`SYNCED` means Envoy acknowledged the last push. `STALE` means `istiod` pushed and Envoy did not acknowledge. `NOT SENT` means nothing of that type was pushed. When a change seems to have no effect, check this first.

## Clusters and endpoints

A **cluster** is a group of upstream hosts that Envoy can route to. The fleet has many Services, so filter the list to one host:

```bash
istioctl proxy-config clusters deployment/mesh-client -n media | grep session-broker
```{{exec}}

Three rows for `session-broker.media.svc.cluster.local`. The `SUBSET` column reads `-` (the Service as a whole), `canary`, and `stable`. `istiod` built one cluster per subset.

```bash
istioctl proxy-config endpoints deployment/mesh-client -n media | grep session-broker
```{{exec}}

**Endpoints** are the pod IPs in each cluster, with a `STATUS` of `HEALTHY`. The `|stable|` cluster has a row. The `|canary|` cluster has no row: no pod carries `version: canary`, so that cluster is empty. A route to it would fail.

## Listener and route

```bash
istioctl proxy-config listeners deployment/mesh-client -n media --port 80
```{{exec}}

A **listener** is an address and port that Envoy accepts on. The 0.0.0.0 row with `Route: 80` sends HTTP on port 80 to the route table named 80, which matches requests by their `Host` header. The Service port is named `http`, which tells Istio to treat the port as HTTP.

The request path in Envoy is listener → route → cluster → endpoint.

## Static checks

```bash
istioctl analyze -n media
```{{exec}}

`No validation issues found`. `analyze` checks the objects themselves, for example a route to a subset that no DestinationRule defines. It does not check whether a subset selects any pods. Only the endpoint list shows that.
