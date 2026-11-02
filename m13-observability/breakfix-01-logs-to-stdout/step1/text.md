# Step 1 — Diagnose the empty log

An empty log on a healthy Pod is a signal. The kubelet captures only stdout and stderr, so the app writes somewhere else.

## The Pod is healthy

```bash
kubectl get pods -n app-services -l app=session-logger
```{{exec}}

The Pod is Running 1/1 with no restarts. The process is up. This is not a crash and not a scheduling problem.

## The log holds one line

```bash
kubectl logs -n app-services deploy/session-logger
```{{exec}}

```text
[session-logger] starting; writing session events to /var/log/app/session.log
```

The app named its log destination: a file, not stdout. Nothing after the banner reaches `kubectl logs`.

## Confirm the lines are on disk

```bash
kubectl exec -n app-services deploy/session-logger -- ls -l /var/log/app
kubectl exec -n app-services deploy/session-logger -- tail -5 /var/log/app/session.log
```{{exec}}

The file `session.log` grows. It holds `session sess-N established` lines. The app works and breaks the logging contract.

No node-level collector sees these lines, because collectors read stdout and stderr. Two fixes follow.
