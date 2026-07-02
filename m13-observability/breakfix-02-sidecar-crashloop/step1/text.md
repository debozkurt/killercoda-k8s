# Step 1 — Find the failing container

`1/2` means one of two containers isn't Ready. The first job is naming *which* — then reading its logs.

## Confirm 1/2, and see the restarts

```bash
kubectl get pods -n signaling -l app=sip-monitor
```{{exec}}

`READY 1/2`, `STATUS CrashLoopBackOff`, `RESTARTS` climbing. One container is fine; one keeps dying. `get pods` won't tell you which — it aggregates.

## Which container? Read the per-container status

```bash
kubectl get pod -n signaling -l app=sip-monitor -o \
  custom-columns='CONTAINER:.status.containerStatuses[*].name,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount'
```{{exec}}

`app` is `true` (Ready), `metrics-agent` is `false` with a climbing restart count. The nginx app serves fine; the **telemetry sidecar** is the one crashlooping.

## The event stream names it too

```bash
kubectl describe pod -n signaling -l app=sip-monitor | sed -n '/Events:/,$p'
```{{exec}}

```text
Warning  BackOff  ...  Back-off restarting failed container=metrics-agent pod=sip-monitor-…
```

The `Warning`/`BackOff` event names `container=metrics-agent`. That's the object the event is *about* — the control plane telling you exactly which container to look at.

## Read the dead instance's logs — `--previous`

The current `metrics-agent` instance is mid-backoff and hasn't printed anything useful. The one that *died* did. Read it:

```bash
kubectl logs -n signaling deploy/sip-monitor -c metrics-agent --previous
```{{exec}}

```text
[metrics-agent] starting; exporting sip-monitor telemetry
/bin/sh: exec: line 3: /usr/local/bin/metrics-agent: not found
```

There's the root cause: the sidecar's command execs `/usr/local/bin/metrics-agent`, a binary that isn't in this image — so it exits non-zero (127) immediately and the kubelet restarts it, forever. `-c` picked the right container; `--previous` showed why the dead one died. On to the fix.
