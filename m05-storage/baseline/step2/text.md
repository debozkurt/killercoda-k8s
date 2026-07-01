# Step 2 — Dynamic provisioning & WaitForFirstConsumer

A StorageClass carries the two settings that decide *how* and *when* a claim gets its volume. Read them, then watch a claim sit `Pending` on purpose — the single most misread state in storage.

## Read the class's recipe

```bash
kubectl get storageclass local-path -o yaml | grep -E 'provisioner:|volumeBindingMode:|reclaimPolicy:'
```{{exec}}

Three fields:

- `provisioner: rancher.io/local-path` — the component that creates the real storage (here, a directory on a node's disk).
- `reclaimPolicy: Delete` — when a bound PVC is deleted, the PV **and its data** are destroyed. (More on the danger of that in step 4 and the lesson.)
- `volumeBindingMode: WaitForFirstConsumer` — don't bind the claim until a Pod actually uses it.

## Watch WaitForFirstConsumer in action

Create a claim with **no** Pod to consume it:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: scratch-demo, namespace: cdr-storage }
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path
  resources: { requests: { storage: 100Mi } }
EOF
```{{exec}}

Check its status:

```bash
kubectl get pvc scratch-demo -n cdr-storage
kubectl describe pvc scratch-demo -n cdr-storage | grep -A2 Events
```{{exec}}

It's `Pending`, and the event says `waiting for first consumer to be created before binding`. **This is healthy, not broken.** With `WaitForFirstConsumer`, the class deliberately delays binding until a Pod uses the claim — because for node-local storage it can't know *which* node's volume to create until the scheduler picks where the Pod runs. A `Pending` claim with no consumer is the system working as designed.

The takeaway you'll need in every scenario: **`Pending` means "broken" only once a Pod is trying to use the claim and it still won't bind.** No consumer, no problem.

Clean up the demo claim:

```bash
kubectl delete pvc scratch-demo -n cdr-storage
```{{exec}}

Next: access modes, and proving the data actually persists.
