# Step 2 — Fix it and verify

The relay should stay on the host network — that's the point of it — but get cluster DNS back. The single field that does that is `dnsPolicy: ClusterFirstWithHostNet`.

## Set the DNS policy

```bash
kubectl patch deployment rtp-relay -n media --type=merge \
  -p '{"spec":{"template":{"spec":{"dnsPolicy":"ClusterFirstWithHostNet"}}}}'
kubectl rollout status deployment/rtp-relay -n media --timeout=90s
```{{exec}}

Or by hand:

```bash
kubectl edit deployment rtp-relay -n media
# under spec.template.spec, change
#   dnsPolicy: ClusterFirst
# to
#   dnsPolicy: ClusterFirstWithHostNet
```

`ClusterFirstWithHostNet` is `ClusterFirst` for a Pod that also happens to be on `hostNetwork` — it points the Pod's resolver at CoreDNS instead of letting it inherit the node's.

## The real-world version

The fix is one field, but the lesson is a rule: **any Pod with `hostNetwork: true` that talks to cluster Services needs `dnsPolicy: ClusterFirstWithHostNet`.** The bug is invisible until the Pod tries to resolve an in-cluster name — the Pod is `Running`, node-local traffic works, and only Service DNS fails. If DNS were failing for *every* Pod (not just the hostNetwork ones), that's a different incident: check CoreDNS in `kube-system` and the `kube-dns` Service's endpoints before touching a workload.

## Verify

```bash
kubectl get deploy rtp-relay -n media -o jsonpath='dnsPolicy={.spec.template.spec.dnsPolicy}{"\n"}'
kubectl exec deploy/rtp-relay -n media -- cat /etc/resolv.conf
kubectl exec deploy/rtp-relay -n media -- getent hosts session-broker.media.svc.cluster.local; echo "exit=$?"
```{{exec}}

`dnsPolicy` is now `ClusterFirstWithHostNet`, `resolv.conf` shows the `kube-dns` nameserver and the `svc.cluster.local` search domains, and the cluster name resolves (`exit=0`) — all while the Pod stays on the host network. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
