# Step 4 — Reading Envoy config with istioctl

When mesh traffic misbehaves, the objects you wrote (VirtualService, DestinationRule, PeerAuthentication) are only the *intent*. What moves packets is the Envoy config istiod compiled and pushed to each sidecar. Debugging the mesh means reading that compiled config. `istioctl` is the lens.

## Is every sidecar in sync?

```bash
istioctl proxy-status
```{{exec}}

`SYNCED` in every column means the sidecar has istiod's latest config. `STALE` or `NOT SENT` means a push didn't land — the pod is running old config, and your new VirtualService may not be in effect yet. Start here: a config bug you can't reproduce is sometimes just an un-synced proxy.

## The four config dumps

Envoy's world is four resource types. Read them for the `mesh-client` sidecar:

```bash
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config clusters "$POD" -n media | grep session-broker
```{{exec}}

A **cluster** is an upstream Envoy can route to. Note the entries for `session-broker` — including one per subset (`stable`, `canary`). Now the endpoints behind them:

```bash
istioctl proxy-config endpoints "$POD" -n media | grep session-broker
```{{exec}}

**Endpoints** are the actual pod IPs in each cluster. The `stable` cluster lists healthy IPs on `:80`; the `canary` cluster is **empty** (no pods carry `version: canary`). An empty cluster is the signature you'll chase in break/fix 02.

```bash
istioctl proxy-config listeners "$POD" -n media | head
istioctl proxy-config routes "$POD" -n media --name 80 | head
```{{exec}}

**Listeners** are the ports Envoy accepts on; **routes** map a request's host/path to a cluster. Together: listener → route → cluster → endpoint. That chain is the mesh's request path, and every break/fix in this module is a break in one link of it.

## The instinct to build

`proxy-status` first (is config current?), then `proxy-config clusters`/`endpoints`/`routes` to walk listener → route → cluster → endpoint. The object you applied says what you *meant*; these dumps say what Envoy is *doing*. When they disagree, the dumps win.
