# Step 2 — Fix it and verify

Create the Service with `clusterIP: None`. A Service with a ClusterIP gives the set one virtual IP and still publishes no per-Pod names.

## Create the governing Service

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: session-store
  namespace: app-services
  labels: { app: session-store, plane: app, tier: lab }
spec:
  clusterIP: None
  selector: { app: session-store }
  ports: [{ port: 80, name: http }]
EOF
```{{exec}}

The `selector` must match the Pods' label `app: session-store`. The Service builds its endpoints from that match.

## Verify

```bash
kubectl describe svc session-store -n app-services
```{{exec}}

Read two lines. `IP:` reads `None`, and `Endpoints:` lists three Pod addresses. Repeat the lookup that failed:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  nslookup session-store-0.session-store.app-services.svc.cluster.local
```{{exec}}

The name resolves to the Pod IP of `session-store-0`. If it still fails, wait a few seconds and run it again, because CoreDNS may briefly cache the earlier failure. Check another ordinal:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  nslookup session-store-1.session-store.app-services.svc.cluster.local
```{{exec}}

Each ordinal resolves to its own Pod. You restarted nothing. The only missing object was the Service. See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m07-workloads-ii/ANSWER-KEY.md) for self-grading, then `finish.md`.
