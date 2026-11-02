# Step 1 — Find the failing container

1/2 means one of two containers is not Ready. Name it first, then read its logs.

## Confirm the restarts

```bash
kubectl get pods -n signaling -l app=sip-monitor
```{{exec}}

READY reads 1/2 and RESTARTS climbs. `get pods` aggregates, so it does not say which container fails.

## Which container?

```bash
kubectl describe pod -n signaling -l app=sip-monitor | grep -E "^  [a-z-]+:$|Ready:|Restart Count|Reason:|Exit Code"
```{{exec}}

Each container prints its own block. `app` is Ready True. `metrics-agent` is Ready False, has a Restart Count above 0, and its Last State is Terminated with Exit Code 1. The nginx app is fine. The telemetry sidecar dies.

## The event names it too

```bash
kubectl events -n signaling --types=Warning
```{{exec}}

```text
Warning   BackOff   pod/sip-monitor-…   Back-off restarting failed container metrics-agent in pod sip-monitor-…
```

The BackOff event names the container. The kubelet waits longer between each restart. That wait is CrashLoopBackOff.

## Read the log

```bash
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent
```{{exec}}

`-c` selects the container. This command reads the current instance when one runs, and the last dead instance while the container waits in back-off. You cannot tell which one you read. If you see only the banner, the new instance has not failed yet. Pin the instance that died:

```bash
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent --previous
```{{exec}}

```text
[metrics-agent] starting; exporting sip-monitor telemetry
[metrics-agent] fatal: COLLECTOR_ENDPOINT is not set
```

The agent needs the environment variable COLLECTOR_ENDPOINT. It waits 15 seconds, finds it empty and exits 1. `--previous` always returns that instance, whatever the container does next. On to the fix.
