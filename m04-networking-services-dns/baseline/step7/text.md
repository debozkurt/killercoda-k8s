# Step 7 — Cluster DNS from inside a Pod

A ClusterIP is stable, but nobody hardcodes 10.96.x.y. Cluster DNS lets you use names. **CoreDNS** runs in `kube-system`, and every Pod is configured to ask it.

## Look at a Pod's resolver config

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  cat /etc/resolv.conf
```{{exec}}

Three lines matter:

- `nameserver` — the `kube-dns` Service ClusterIP, with CoreDNS behind it.
- `search media.svc.cluster.local svc.cluster.local cluster.local` — the domains a short name is tried under. **Built from this Pod's namespace**, `media`.
- `options ndots:5` — names with fewer than 5 dots are tried with the search domains appended first.

## Resolve a Service by name

Every Service gets a record at `<svc>.<ns>.svc.cluster.local`. From a Pod in `media`, the short name resolves because `media` is in the search list:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-broker
```{{exec}}

The `Name:` line in the answer shows what the resolver actually asked for: `session-broker.media.svc.cluster.local`. The short name is just the FQDN with the search list filling in the rest, and `Address:` is the same ClusterIP `get svc` showed you.

## A cross-namespace lookup

A caller outside `media` has to carry the namespace. This is the lookup `account-provisioner` does to reach the broker:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n provisioning -- \
  nslookup session-broker.media.svc.cluster.local
```{{exec}}

It resolves from `provisioning` because the name is complete. Application config often writes the shorter `session-broker.media` and lets the search list finish it — that works in glibc-based images, but busybox's resolver skips the search list for any name that already contains a dot, so probe Pods like this one need the full FQDN.

## A headless Service answers a different shape

`media-engine` governs a StatefulSet and sets `clusterIP: None`, so DNS hands back the Pods instead of a virtual IP:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup media-engine
```{{exec}}

Two `Address` lines, one per Ready Pod, and no ClusterIP anywhere. That is what `clusterIP: None` buys: the client sees the individual Pods and chooses one. Each Pod also has its own stable name:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup media-engine-0.media-engine.media.svc.cluster.local
```{{exec}}

That per-Pod name is why stateful systems use headless Services — a replica has to be addressable *as itself*, not as "one of the pool".

## See the resolver itself

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
kubectl get svc kube-dns -n kube-system
```{{exec}}

CoreDNS is a normal Deployment fronted by a normal Service — when *all* DNS fails clusterwide, this is what you check. For now it's healthy. The catch you'll hit next: that short name only worked because the client shared the target's namespace.
