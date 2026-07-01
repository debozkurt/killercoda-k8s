# Step 2 — StatefulSet identity: ordinals and per-Pod DNS

A stable name is only useful if peers can *reach* that name. That's what the headless Service does.

## The governing Service is headless

Every StatefulSet names a governing Service in `spec.serviceName`:

```bash
kubectl get statefulset media-engine -n media -o jsonpath='{.spec.serviceName}'; echo
```{{exec}}

`media-engine`. Now look at that Service — its `CLUSTER-IP`:

```bash
kubectl get svc media-engine -n media
```{{exec}}

`CLUSTER-IP` is `None` — a **headless** Service. It has no virtual IP; instead, cluster DNS publishes one A record per Pod. That's what turns an ordinal name into an address.

## Each ordinal resolves to itself

Spin up a throwaway client and resolve a specific member by its per-Pod DNS name, `<pod>.<service>.<ns>.svc.cluster.local`:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup media-engine-0.media-engine.media.svc.cluster.local
```{{exec}}

It resolves to `media-engine-0`'s Pod IP. Try the other ordinal:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup media-engine-1.media-engine.media.svc.cluster.local
```{{exec}}

A different IP — `media-engine-1`'s. This is the guarantee: `media-engine-0` is addressable *as a specific peer*, not load-balanced across replicas. Delete and recreate the Pod and the name still points at the ordinal. Stateful systems (leader election, replication) need exactly this. Next: the storage that follows each ordinal the same way.
