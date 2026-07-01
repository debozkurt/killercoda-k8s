# Step 1 — Diagnose the missing per-Pod DNS

The Pods are healthy; discovery is not. Prove where it breaks before touching anything.

## The Pods are fine

```bash
kubectl get pods -n media -l app=session-cache -o wide
```{{exec}}

All three `Running`, stable ordinal names, on a node with IPs. Nothing here is broken — so the failure is in how peers *find* each other, not in the members themselves.

## The per-Pod name won't resolve

A peer addresses a specific member by its stable DNS name. Try it:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-cache-0.session-cache.media.svc.cluster.local
```{{exec}}

It fails to resolve (`can't resolve` / NXDOMAIN). That name is exactly what worked in the baseline tour. Now resolve the *Service* name instead:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-cache.media.svc.cluster.local
```{{exec}}

This one resolves — but to a **single IP** that isn't any Pod's. A headless Service returns the set of Pod IPs; a single VIP is what a *normal* Service returns. That's the tell.

## First look: is the Service still headless?

```bash
kubectl get svc -n media session-cache
```{{exec}}

The `CLUSTER-IP` column shows a real IP, not `None`. This Service isn't headless anymore. Confirm the field directly:

```bash
kubectl get svc session-cache -n media -o jsonpath='{.spec.clusterIP}{"\n"}'
```{{exec}}

It's an IP (e.g. `10.96.x.x`), not `None`. That's the root cause: per-Pod DNS records (`session-cache-0.session-cache...`) are published **only** for a headless Service. The moment this Service got a VIP, those records disappeared and peer discovery broke — even though every Pod is perfectly healthy. On to the fix, which has one catch.
