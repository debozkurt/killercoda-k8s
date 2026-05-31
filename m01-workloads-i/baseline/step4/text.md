# Step 4 — Graceful shutdown

Deleting a Pod is not instant, and it shouldn't be. The kubelet runs an ordered sequence so in-flight work can drain before the process dies. `sip-app` is configured for it.

## Read the shutdown controls

```bash
kubectl get deploy sip-app -n app-services -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}{"\n"}{.spec.template.spec.containers[0].lifecycle.preStop}{"\n"}'
```{{exec}}

Two controls print: `terminationGracePeriodSeconds: 30` and a `preStop` hook running `sleep 5`. Together they define the termination sequence:

```text
delete issued
   │  Pod → Terminating, removed from Service Endpoints (stops NEW traffic)
   ├─ preStop hook runs  (sleep 5 — lets kube-proxy finish deregistering)
   ├─ SIGTERM sent to PID 1  (app drains and exits)
   └─ grace expires (30s) → SIGKILL  (only if it hasn't exited yet)
```

The `preStop` sleep buys time for load balancers to stop sending new connections *before* the app starts refusing them — endpoint removal and `SIGTERM` otherwise race. The grace period is the total budget: `preStop` + `SIGTERM` handling both spend from it.

## Watch a graceful delete in real time

```bash
POD=$(kubectl get pod -n app-services -l app=sip-app -o jsonpath='{.items[0].metadata.name}')
time kubectl delete pod $POD -n app-services
```{{exec}}

The command blocks for ~5+ seconds, not instantly — that's the `preStop` drain running before the container gets `SIGTERM`. A workload with no grace handling would vanish immediately and drop whatever it was holding. (Set `terminationGracePeriodSeconds: 1` here and the kubelet would `SIGKILL` mid-drain — exactly the bug in `breakfix-03`.)

## Verify

```bash
kubectl get pods -n app-services -l app=sip-app
```{{exec}}

The ReplicaSet has already replaced the deleted Pod — back to `2/2`, both `Running`. You've now watched the full life of a Pod: created by a controller, judged by probes, and shut down gracefully. The breakfix scenarios break one piece of this each.

For the *why* behind everything here, read [`LESSON.md`](../LESSON.md). When you're ready to be tested, start **`breakfix-01-liveness-restart-loop`**.
