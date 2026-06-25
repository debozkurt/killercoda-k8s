# Step 4 — Cluster DNS from inside a Pod

A ClusterIP is stable, but nobody hardcodes `10.96.x.y`. Cluster DNS lets you use names. **CoreDNS** runs in `kube-system`, and every Pod is configured to ask it.

## Look at a Pod's resolver config

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  cat /etc/resolv.conf
```{{exec}}

Three lines matter:

- `nameserver <ip>` — the `kube-dns` Service ClusterIP (CoreDNS sits behind it).
- `search media.svc.cluster.local svc.cluster.local cluster.local` — the domains a short name is tried under. **Built from this Pod's namespace (`media`)** — that detail is the whole of breakfix-01.
- `options ndots:5` — names with fewer than 5 dots are tried with the search domains appended first.

## Resolve a Service by name

Every Service gets a record at `<svc>.<ns>.svc.cluster.local`. From a Pod in `media`, the short name resolves because `media` is in the search list:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-broker
```{{exec}}

The fully-qualified name resolves to the same ClusterIP:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-broker.media.svc.cluster.local
```{{exec}}

Same `Address` both times — the short name is just the FQDN with the search list filling in `.media.svc.cluster.local`.

## See the resolver itself

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
kubectl get svc kube-dns -n kube-system
```{{exec}}

CoreDNS is a normal Deployment fronted by a normal Service — when *all* DNS fails clusterwide, this is what you check. For now it's healthy. The catch you'll hit next: that short name only worked because the client shared the target's namespace.
</content>
