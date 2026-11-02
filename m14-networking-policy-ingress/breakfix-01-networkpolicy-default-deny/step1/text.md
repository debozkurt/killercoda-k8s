# Step 1 — Diagnose the silent timeout

The Pods are Ready, the Service has endpoints, and DNS resolves, yet the connection hangs. Confirm each layer before you blame a policy.

## Reproduce the failure

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

The call hangs, then fails with `wget: download timed out`. It did not return NXDOMAIN or connection refused. Those two loud failures from M04 are ruled out.

## Rule out the M04 layers

```bash
kubectl get endpoints session-broker -n media
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-broker.media.svc.cluster.local
```{{exec}}

The endpoints list Pod IPs on port 80, and the name resolves to the ClusterIP. The request should arrive. Something drops it after both checks.

## Find the policy

```bash
kubectl get networkpolicy -n media
kubectl describe networkpolicy default-deny-ingress -n media
```{{exec}}

The policy has an empty PodSelector, so it selects every Pod in media. Its ingress section reads `<none> (Selected pods are isolated for ingress connectivity)`. It is the only policy in the namespace. The baseline had a second one that allowed a caller. That allow is gone. On to the fix.
