# Step 5 — Self-heal and cascade

Two statements need proof: the operator repairs drift without a restart, and deleting a tenant removes its whole tree.

## Delete a child, watch it return

Delete the child Deployment of `orion`. You do not own it. The operator does:

```bash
kubectl delete deployment orion-media -n media
sleep 15
kubectl get deployments -n media -l managed-by=tenant-operator
kubectl logs deployment/tenant-operator -n platform --tail=8
```{{exec}}

`orion-media` is back with a new `AGE`. The logs show `creating child deployment orion-media`. The loop compares desired state with observed state on every pass, so a missed event or a deleted child heals on the next pass. This is **level-triggered** behavior.

## Delete a tenant, watch the tree go

Delete the tenant `lyra`:

```bash
kubectl delete mediatenant lyra -n media
```{{exec}}

The command waits a few seconds. The tenant carries the operator's finalizer, so the API server holds the object until the operator finishes its cleanup and removes the finalizer. The operator's log says `cleanup done, finalizer removed`. Then the garbage collector follows the ownerReference:

```bash
sleep 10
kubectl get deployment,replicaset,pod -n media -l app=lyra-media
```{{exec}}

No resources found, or Pods that read `Terminating`. You deleted one object, and the owner reference removed the Deployment, its ReplicaSet and its Pods.

Two threads, two jobs. The **ownerReference** removes the children. The **finalizer** holds the owner until cleanup runs. The break/fix scenarios break each thread.
