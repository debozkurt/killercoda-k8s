# Step 1 — Diagnose the restart loop

`CrashLoopBackOff` tells you a container keeps exiting and the kubelet is backing off between restarts. It does **not** tell you *why*. Resist the urge to assume the app is broken — find out.

## Confirm the symptom

```bash
kubectl get pods -n call-routing
```{{exec}}

Both `route-engine` pods show `CrashLoopBackOff` (or `Running` with a `RESTARTS` count climbing every ~15 seconds). Re-run it a few times — a rising restart count is the signature of a loop, not a one-off failure.

## Ask the dead container what happened

The container that just got killed left logs. Read them with `--previous` (the *current* container may have only just started and have nothing yet).

```bash
POD=$(kubectl get pod -n call-routing -l app=route-engine -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD -n call-routing --previous
```{{exec}}

You'll see normal nginx startup lines — and then nothing. No panic, no stack trace, no error. The application **did not crash.** A clean log that simply stops is the first clue that something *external* is killing a healthy process.

## Find what's doing the killing

If the app didn't die on its own, who killed it? `describe` shows the kubelet's decisions as events.

```bash
kubectl describe pod $POD -n call-routing
```{{exec}}

Read the `Events:` section and the container's `Last State`. The smoking gun:

```text
  Warning  Unhealthy  ...  Liveness probe failed: HTTP probe failed with statuscode: 404
  Normal   Killing    ...  Container app failed liveness probe, will be restarted
```

`Last State: Terminated, Reason: Error` — but with **liveness** events right before it. That's the difference from a real crash: a genuine crash shows a `Terminated` state with *no* liveness events; this shows the kubelet killing the container *because the probe failed*.

## Read the probe that's lying

```bash
kubectl describe deploy route-engine -n call-routing
```{{exec}}

In the `Pod Template` section, the container's `Liveness:` line spells out what's being checked:

```text
    Liveness:  http-get http://:http/healthz delay=0s timeout=1s period=10s #success=1 #failure=3
```

There's the bug: the probe checks `/healthz`, but this app (nginx) serves `/`, not `/healthz` — so every check gets a `404`, and only `2xx`/`3xx` pass. The probe is killing a container that was never sick. On to the fix.
