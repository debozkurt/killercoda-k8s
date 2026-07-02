# Step 1 — Diagnose the wedged StatefulSet

Two facts to establish: only ordinal 0 exists, and it isn't Ready. The second explains the first.

## The set is stuck, and a replica is missing

```bash
kubectl get statefulset session-cache -n media
kubectl get pods -n media -l app=session-cache
```{{exec}}

The StatefulSet reads `READY 0/3`, and there is exactly one Pod — `session-cache-0`, showing `0/1` (Running, but not Ready). No `session-cache-1`, no `session-cache-2`. This is not a scheduling failure: the higher ordinals were never *created*, so there's no Pending Pod to describe.

Why? Because the default `podManagementPolicy` is **`OrderedReady`**: the controller will not create ordinal N+1 until ordinal N is Running **and Ready**. `session-cache-0` is Running but not Ready, so the controller is waiting — and `session-cache-1` will never appear until `-0` passes. The whole set is wedged behind ordinal 0.

## Why isn't ordinal 0 Ready?

Not Ready means a readiness probe is failing. Ask the Pod:

```bash
kubectl describe pod session-cache-0 -n media | grep -A8 Events
```{{exec}}

The events show the readiness probe failing repeatedly — `Readiness probe failed: ... connection refused`. Read what the probe actually checks:

```bash
kubectl get statefulset session-cache -n media \
  -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet}{"\n"}'
```{{exec}}

The probe does an HTTP GET on **port 8080**. But the container is nginx, which serves on **port 80** — nothing listens on 8080, so every probe gets `connection refused` and the Pod never crosses into Ready. The container is healthy; the *probe* points at the wrong port. That's the root cause, and because of `OrderedReady`, that one wrong port halts the entire StatefulSet. On to the fix.
