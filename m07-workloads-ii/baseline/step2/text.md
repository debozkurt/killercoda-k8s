# Step 2 — StatefulSet identity: ordinals and per-Pod DNS

A stable name helps only if peers can resolve it. A **headless Service** (a Service with no virtual IP) publishes that name.

## The governing Service

Every StatefulSet names its **governing Service** in `serviceName`:

```bash
kubectl get statefulset media-engine -n media -o yaml | grep serviceName
```{{exec}}

The line reads `serviceName: media-engine`. Describe the Service with that name:

```bash
kubectl describe svc media-engine -n media
```{{exec}}

Read the `IP:` line. It reads `None`, so the Service is headless. The `Endpoints:` line lists one address per Pod. With no virtual IP, cluster DNS answers with those Pod addresses and publishes one record per Pod.

## Each ordinal resolves to itself

Resolve one member by its per-Pod DNS name, `<pod>.<service>.<namespace>.svc.cluster.local`:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup media-engine-0.media-engine.media.svc.cluster.local
```{{exec}}

The answer is the Pod IP of `media-engine-0`. Resolve the other ordinal:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup media-engine-1.media-engine.media.svc.cluster.local
```{{exec}}

A different IP. A peer can address one specific member, and no virtual IP balances the traffic. Next: the disk that follows each ordinal.
