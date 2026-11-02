# Step 2 — Fix it and verify

The sidecar needs an address for the collector, the service that receives its telemetry. Set it on the sidecar only.

## Set the variable

```bash
kubectl set env deployment/sip-monitor -n signaling -c metrics-agent COLLECTOR_ENDPOINT=collector.platform.svc:4317
```{{exec}}

This edits the Pod template, so the Deployment starts a new Pod. The new `metrics-agent` has the variable, so it passes the check, reports ready and stays up.

## Roll out and verify

```bash
kubectl rollout status deployment sip-monitor -n signaling --timeout=90s
kubectl get pods -n signaling -l app=sip-monitor
```{{exec}}

READY reads 2/2 and the restart count stays at 0. The agent waits 15 seconds before it exports. Run this after 20 seconds:

```bash
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent --tail=3
```{{exec}}

The agent prints exported telemetry batch. The telemetry is flowing. The app never changed. One missing variable on the sidecar caused the whole failure. Read `finish.md`, then check `ANSWER-KEY.md`.
