# Step 2 — Headless Service & per-Pod DNS

A normal Service hands you one virtual IP and load-balances across the Pods behind it — deliberately hiding *which* replica you reached. Coordination needs the opposite: reach `session-cache-1` specifically. A **headless Service** (`clusterIP: None`) is how. It has no VIP; instead cluster DNS publishes a name per Pod.

## See the headless Service

```bash
kubectl get svc -n media session-cache
```{{exec}}

`CLUSTER-IP` reads `None` — that's what "headless" means. Compare a normal one:

```bash
kubectl get svc -n media session-broker
```{{exec}}

`session-broker` has a real `CLUSTER-IP` (a VIP that round-robins). `session-cache` has none. The StatefulSet points at this Service through its `serviceName: session-cache` field — that's what wires up per-Pod DNS.

## Resolve a specific member by name

The fleet's nginx Pods don't run DNS tools, so spin up a throwaway `busybox` client. Look up one member by its stable name:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-cache-0.session-cache.media.svc.cluster.local
```{{exec}}

It resolves to `session-cache-0`'s Pod IP. The name format is `<pod>.<service>.<namespace>.svc.cluster.local` — a stable address for one specific member, published *because* the governing Service is headless. Now resolve the Service name itself:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-cache.media.svc.cluster.local
```{{exec}}

A headless Service name returns **all** the member IPs (all three Pods), not a single VIP — a peer can enumerate the whole set, then address any member directly. Contrast the normal Service:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-broker.media.svc.cluster.local
```{{exec}}

`session-broker` resolves to one VIP — the Service IP, not any Pod's. That's the whole distinction: **normal Service = one VIP that hides members; headless Service = a name per member so peers can find each other.** Next: the order those members come up in.
