# Step 1 — hostNetwork: the Pod is the node

`rtp-relay` runs with `hostNetwork: true`. It shares the node's network namespace instead of getting its own — so its Pod IP *is* the node's IP, and it binds the node's real ports directly (what a media relay needs for line-rate UDP, with no overlay hop).

## The Pod IP equals the node IP

```bash
kubectl get pod -n media -l app=rtp-relay -o wide
kubectl get nodes -o wide
```{{exec}}

The relay's `IP` matches the `INTERNAL-IP` of the node it landed on — not a pod-network address. Confirm the flag that causes it:

```bash
kubectl get pod -n media -l app=rtp-relay \
  -o jsonpath='{range .items[*]}hostNetwork={.spec.hostNetwork}  dnsPolicy={.spec.dnsPolicy}{"\n"}{end}'
```{{exec}}

`hostNetwork=true` and `dnsPolicy=ClusterFirstWithHostNet`. That second field is not optional here — hold onto it.

## Reach it on the node's own IP

The relay listens on the node directly, so you reach it at the node IP — no Service, no ClusterIP:

```bash
NODE_IP=$(kubectl get pod -n media -l app=rtp-relay -o jsonpath='{.items[0].status.hostIP}')
curl -s --max-time 5 http://$NODE_IP:80 | head -1
```{{exec}}

nginx's welcome line comes back from the node's `:80`. A normal Pod's `:80` would be reachable only through a Service; this one owns the node port.

## It still has cluster DNS — because it asked for it

```bash
kubectl exec deploy/rtp-relay -n media -- cat /etc/resolv.conf
kubectl exec deploy/rtp-relay -n media -- getent hosts session-broker.media.svc.cluster.local
```{{exec}}

`resolv.conf` shows the `kube-dns` nameserver and the `svc.cluster.local` search domains, and the in-cluster name resolves to a ClusterIP. That works **only** because `dnsPolicy: ClusterFirstWithHostNet` is set. Leave it at the default and a hostNetwork Pod gets the *node's* resolver instead — the trap in breakfix-01.
