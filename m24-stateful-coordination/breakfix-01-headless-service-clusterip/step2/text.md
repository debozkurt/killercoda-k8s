# Step 2 — Fix it and verify

The Service needs `clusterIP: None` back. The catch: **a Service's `clusterIP` is immutable** — once it's assigned a VIP you can't edit it back to `None`. Try, and the API refuses:

```bash
kubectl patch svc session-cache -n media -p '{"spec":{"clusterIP":"None"}}'
```{{exec}}

Rejected (`may not change once set` / field is immutable). To make a Service headless after the fact, you delete and recreate it. Deleting the Service does **not** touch the Pods or their PVCs — only the DNS front:

```bash
kubectl delete svc session-cache -n media
```{{exec}}

Recreate it headless (`clusterIP: None`), matching the StatefulSet's `serviceName`:

```bash
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: session-cache
  namespace: media
  labels: { app: session-cache, plane: media, tier: lab }
spec:
  clusterIP: None
  selector: { app: session-cache }
  ports: [{ port: 6379, name: cache }]
EOF
```{{exec}}

## Verify

```bash
kubectl get svc session-cache -n media
```{{exec}}

`CLUSTER-IP` reads `None` again. Now the per-Pod name resolves:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-cache-0.session-cache.media.svc.cluster.local
```{{exec}}

`session-cache-0.session-cache.media.svc.cluster.local` resolves to Pod-0's IP — per-Pod DNS is published again and peers can address specific members. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
