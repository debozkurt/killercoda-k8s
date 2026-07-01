# Step 1 — Diagnose the stalled rollout

Two facts to establish: only Pod-0 exists, and Pod-0 isn't Ready. The second explains the first.

## Only one Pod, and the set is 0/3

```bash
kubectl get statefulset session-store -n app-services
kubectl get pods -n app-services -l app=session-store
```{{exec}}

`READY 0/3`, and a single Pod — `session-store-0` — `Running` but `0/1` ready. No `session-store-1`, no `session-store-2`. They weren't deleted; they were never created. That's the tell of an `OrderedReady` StatefulSet: the controller creates ordinals one at a time and won't start Pod-1 until Pod-0 is **Ready**. Pod-0 isn't, so the sequence is stuck at the gate.

## Why isn't Pod-0 Ready?

```bash
kubectl describe pod session-store-0 -n app-services | grep -A8 Conditions
kubectl describe pod session-store-0 -n app-services | grep -A6 Events
```{{exec}}

`Ready: False`, and the events show the readiness probe failing — `Readiness probe failed: ... connection refused`. The container is up, but the probe can't get a passing response, so the kubelet never marks the Pod Ready.

## Read the probe and the port it targets

```bash
kubectl get statefulset session-store -n app-services \
  -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet}'; echo
kubectl get statefulset session-store -n app-services \
  -o jsonpath='{.spec.template.spec.containers[0].ports}'; echo
```{{exec}}

The readiness probe does an HTTP GET on **port 8080** — but the container's only port is **80**. Nothing is listening on 8080, so every probe is refused, the Pod stays `0/1`, and `OrderedReady` holds the rest of the set behind it. The fix is to point the probe at the port the container actually serves.
