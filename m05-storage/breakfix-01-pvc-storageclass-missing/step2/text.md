# Step 2 — Fix it and verify

The claim needs the real class, `local-path`. The catch: **`storageClassName` is immutable** — you can't edit it on an existing PVC. Try it and the API refuses:

```bash
kubectl patch pvc cdr-data -n cdr-storage -p '{"spec":{"storageClassName":"local-path"}}'
```{{exec}}

It's rejected (`field is immutable`). To change the class, you delete and recreate the claim. That's safe here because the claim never bound — there's no data to lose. Because a Pod references the claim, remove the consumer first so the delete doesn't hang on it:

```bash
kubectl scale deployment cdr-writer -n cdr-storage --replicas=0
kubectl delete pvc cdr-data -n cdr-storage
```{{exec}}

Recreate the claim with the correct class:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: cdr-data, namespace: cdr-storage }
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path
  resources: { requests: { storage: 1Gi } }
EOF
```{{exec}}

Bring the workload back — its Pod is the first consumer, so `WaitForFirstConsumer` binds the volume as it schedules:

```bash
kubectl scale deployment cdr-writer -n cdr-storage --replicas=1
```{{exec}}

## Verify

```bash
kubectl get pvc cdr-data -n cdr-storage
kubectl wait --for=condition=Ready pod -l app=cdr-writer -n cdr-storage --timeout=60s
kubectl get pods -n cdr-storage
```{{exec}}

`cdr-data` is now `Bound` (to a `local-path` PV), and `cdr-writer` is `Running` and `Ready` — the volume provisioned as soon as a Pod consumed the claim. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
