# Step 2 — Fix it and verify

The StatefulSet points `serviceName: session-store` at a Service that doesn't exist. Create it — and it must be **headless** (`clusterIP: None`), because per-Pod DNS records only come from a headless Service selecting the Pods.

## Create the governing headless Service

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

`clusterIP: None` is the load-bearing line — a normal ClusterIP Service would give the *set* one virtual IP but still wouldn't publish the per-Pod names the members need. The `selector` must match the Pods' `app: session-store` label so the Service's EndpointSlice picks them up.

## Verify the per-Pod names now resolve

Give DNS a couple of seconds to pick up the new Endpoints, then repeat the lookup that failed:

```bash
kubectl get svc session-store -n app-services
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  nslookup session-store-0.session-store.app-services.svc.cluster.local
```{{exec}}

The Service shows `CLUSTER-IP: None`, and the lookup now resolves to `session-store-0`'s Pod IP. Confirm the other ordinals too:

```bash
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  nslookup session-store-1.session-store.app-services.svc.cluster.local
```{{exec}}

Each ordinal resolves to its own Pod. The Pods never changed — you didn't restart or reschedule anything. All that was missing was the Service that turns their stable names into DNS records. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
