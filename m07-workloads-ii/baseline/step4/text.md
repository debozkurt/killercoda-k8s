# Step 4 — Delete a Pod, keep the identity

Two statements need proof: the replacement Pod keeps its claim and its data, and a scale-down keeps the claim.

## Write data, then delete the Pod

Write a marker file into the volume of `media-engine-0`, and note the Pod's IP:

```bash
kubectl exec media-engine-0 -n media -- sh -c 'echo seed-node > /var/state/role; cat /var/state/role'
kubectl get pod media-engine-0 -n media -o wide
```{{exec}}

Delete the Pod. The StatefulSet controller creates a replacement:

```bash
kubectl delete pod media-engine-0 -n media
```{{exec}}

Wait until the replacement is Ready, then compare:

```bash
kubectl wait --for=condition=Ready pod/media-engine-0 -n media --timeout=90s
kubectl get pod media-engine-0 -n media -o wide
kubectl exec media-engine-0 -n media -- cat /var/state/role
```{{exec}}

The name is the same. `AGE` is new, and the IP is usually new. The file survives, because the replacement mounted `state-media-engine-0` again. Resolve the per-Pod name:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup media-engine-0.media-engine.media.svc.cluster.local
```{{exec}}

The record points at the new IP. The name followed the ordinal.

## Scale down, then up

Write a marker into ordinal 1, then scale the set to one replica:

```bash
kubectl exec media-engine-1 -n media -- sh -c 'echo replica > /var/state/role'
kubectl scale statefulset media-engine -n media --replicas=1
kubectl get pods,pvc -n media
```{{exec}}

`media-engine-1` is gone, but `state-media-engine-1` is still `Bound`. The controller keeps the claim. Scale back to two and read the marker:

```bash
kubectl scale statefulset media-engine -n media --replicas=2
kubectl wait --for=condition=Ready pod/media-engine-1 -n media --timeout=90s
kubectl exec media-engine-1 -n media -- cat /var/state/role
```{{exec}}

The marker is still there. Next: the other controller.
