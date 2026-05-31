# Step 1 — Diagnose the truncated drain

`kubectl get pods` won't help here — the pod is healthy. This failure lives in the shutdown path. Read the controls that govern shutdown, then reproduce the truncation and time it.

## Read the termination controls

```bash
kubectl get deploy session-broker -n media \
  -o jsonpath='grace={.spec.template.spec.terminationGracePeriodSeconds}{"\n"}preStop={.spec.template.spec.containers[0].lifecycle.preStop}{"\n"}'
```{{exec}}

Two values come back:

```text
grace=1
preStop={"exec":{"command":["/bin/sleep","15"]}}
```

There's the mismatch. The `preStop` hook needs **15 seconds** to drain in-flight sessions. The `terminationGracePeriodSeconds` is **1**. The grace period is the *total* budget for shutdown — `preStop` and `SIGTERM` handling both spend from it. A 1-second budget can't fit a 15-second drain.

## Recall the sequence

```text
delete issued
   ├─ preStop runs (wants 15s) ───┐
   ├─ SIGTERM to the app          │  bounded by terminationGracePeriodSeconds (= 1s)
   └─ grace expires → SIGKILL ─────┘
```

When the grace period expires with `preStop` still running, the kubelet grants one short (~2s) extension, then sends `SIGKILL`. So the drain that wanted 15 seconds gets cut off after ~3 — every time the pod terminates.

## Reproduce it — time a shutdown

Deleting the pod runs the exact same termination sequence a rollout or scale-down does. Time it:

```bash
POD=$(kubectl get pod -n media -l app=session-broker -o jsonpath='{.items[0].metadata.name}')
time kubectl delete pod $POD -n media
```{{exec}}

The delete returns in **~1–3 seconds**, not the ~15 the drain needs. That gap *is* the dropped sessions: the kubelet `SIGKILL`ed the container while `preStop` was still draining. A correctly-sized workload would block here for the full drain before the pod disappeared.

The ReplicaSet immediately replaces the pod, so the service stays up — but every one of those terminations truncated its drain. On to the fix: make the budget fit the work.
