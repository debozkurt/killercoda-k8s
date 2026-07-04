# Step 1 — Diagnose the resolver a hostNetwork Pod got

The Pod is `Running`, so don't look for a crash. The failure is in name resolution — read the resolver the relay was handed, and compare it to a normal Pod's.

## Confirm the relay is up, then read its resolver

```bash
kubectl get pod -n media -l app=rtp-relay -o wide
kubectl exec deploy/rtp-relay -n media -- cat /etc/resolv.conf
```{{exec}}

The Pod is `Running` — but its `resolv.conf` is the **node's**: the `nameserver` is the node's upstream resolver, and there's no `search ... svc.cluster.local` line. That's the whole problem. Prove it can't resolve a cluster name:

```bash
kubectl exec deploy/rtp-relay -n media -- getent hosts session-broker.media.svc.cluster.local; echo "exit=$?"
```{{exec}}

Nothing comes back and `exit=2` — the name doesn't resolve. A cluster Service the rest of the fleet reaches fine is invisible to this Pod.

## Compare with a Pod that uses cluster DNS

Any normal (non-hostNetwork) Pod resolves it. Check one from the fleet:

```bash
kubectl exec deploy/session-broker -n media -- cat /etc/resolv.conf
```{{exec}}

This one's `nameserver` is the `kube-dns` ClusterIP and it carries the `svc.cluster.local` search domains. Same cluster, different resolver — the difference is host networking.

## Find the field that caused it

```bash
kubectl get pod -n media -l app=rtp-relay \
  -o jsonpath='{range .items[*]}hostNetwork={.spec.hostNetwork}  dnsPolicy={.spec.dnsPolicy}{"\n"}{end}'
```{{exec}}

`hostNetwork=true` with `dnsPolicy=ClusterFirst`. That combination is the trap: `ClusterFirst` is *ignored* for a hostNetwork Pod, so it silently falls back to the node's resolver. To get cluster DNS on the host network you must say so explicitly — `dnsPolicy: ClusterFirstWithHostNet`. On to the fix.
