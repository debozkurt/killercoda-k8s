# Step 1 — Diagnose the failed lookups

A name failure can mean DNS is down, or it can mean something blocks the DNS query. Test each possibility.

## Reproduce the failure

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local./
```{{exec}}

After several seconds the call fails with `wget: bad address`. The trailing dot makes the name absolute, so the resolver skips the search domains and fails sooner. A short name such as session-broker tries every search domain, and each attempt waits for a timeout. A blocked DNS query therefore looks like a slow hang.

## Is DNS itself healthy?

Resolve the same name from a namespace without a policy:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  nslookup session-broker.media.svc.cluster.local.
kubectl get pods -n kube-system -l k8s-app=kube-dns
```{{exec}}

The name resolves, and the CoreDNS Pods are Running. DNS works. The failure is specific to media.

## Does the network path work?

Call the Service by its ClusterIP and skip DNS. Read the CLUSTER-IP column first:

```bash
kubectl get svc session-broker -n media
```{{exec}}

Replace CLUSTER-IP with the address you read:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://CLUSTER-IP/
```

nginx answers. Pod traffic inside media works. Only the name lookup fails.

## Find the policy

```bash
kubectl get networkpolicy -n media
kubectl describe networkpolicy restrict-egress-to-namespace -n media
```{{exec}}

Policy Types reads Egress. The egress section allows one destination: a PodSelector with no labels, which means every Pod in media. CoreDNS runs in kube-system, so no rule allows the DNS query. The ClusterIP call worked because its backend Pod is in media. On to the fix.
