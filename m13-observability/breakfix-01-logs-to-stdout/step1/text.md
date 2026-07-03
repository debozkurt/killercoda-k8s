# Step 1 — Diagnose the empty log

A healthy Pod with an empty log is a signal, not a dead end. The kubelet captures **stdout/stderr only** — so an empty log means the app isn't writing there.

## The Pod is genuinely healthy

```bash
kubectl get pods -n app-services -l app=session-logger
```{{exec}}

`Running`, `1/1`, no restarts. Not a crash, not a scheduling problem — the process is up.

## But the log is nearly empty

```bash
kubectl logs -n app-services deploy/session-logger
```{{exec}}

One line:

```text
[session-logger] starting; writing session events to /var/log/app/session.log
```

Read it — the app *told you where it logs*: a file, `/var/log/app/session.log`. It's writing session activity there, not to stdout. `kubectl logs` only sees stdout, so everything after the banner is invisible to it.

## Confirm the logs are on disk, not on stdout

```bash
kubectl exec -n app-services deploy/session-logger -- ls -l /var/log/app
kubectl exec -n app-services deploy/session-logger -- tail -5 /var/log/app/session.log
```{{exec}}

There they are — a growing `session.log` full of `session sess-N established …` lines the app has been writing all along. The app is fine; it just breaks the container logging contract by writing to a file instead of stdout.

## Why this matters

Nothing captured those lines. They're on the container's filesystem, and they'll die with the Pod — no node collector or central store ever sees them, because the whole log pipeline keys on stdout/stderr. The fix is to get that output onto stdout. Two ways, next.
