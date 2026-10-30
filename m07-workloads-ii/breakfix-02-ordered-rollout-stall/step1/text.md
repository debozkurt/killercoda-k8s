# Step 1 — Diagnose the stalled rollout

Establish two facts: only ordinal 0 exists, and ordinal 0 is not Ready. The second explains the first.

## One Pod, and the set reads 0/3

```bash
kubectl get statefulset session-store -n app-services
kubectl get pods -n app-services -l app=session-store
```{{exec}}

`READY 0/3`, and one Pod that is `Running` and `0/1`. The missing Pods were never created. Under the default `OrderedReady` policy, the controller creates ordinal 1 only after ordinal 0 is Running and Ready. Ordinal 0 never became Ready, so the controller waits at that gate.

## Why is ordinal 0 not Ready?

```bash
kubectl describe pod session-store-0 -n app-services
```{{exec}}

Read four places in the output:

- `Ready` under `Conditions:` is `False`.
- The `Readiness:` line shows an HTTP check on port 8080.
- The `Port:` line under the container shows that it serves port 80.
- The `Events:` block ends with `Readiness probe failed ... connection refused`.

The container is up, and the kubelet cannot get a passing answer from its probe, so it never marks the Pod Ready. The probe checks 8080, and nothing listens there. Every probe is refused, and `OrderedReady` holds the rest of the set behind ordinal 0. Next: fix the port, and watch what the controller does.
