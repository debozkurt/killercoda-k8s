# Step 1 — Diagnose the OOMKill

This Pod is not `Pending`. The scheduler did its job, so the problem is at runtime, and the `FailedScheduling` event does not exist. Read the container's last state instead.

## It scheduled, then it did not stay up

```bash
kubectl get pods -n media -l app=media-buffer -o wide
```{{exec}}

The Pod has a `NODE`, the `STATUS` reads `CrashLoopBackOff` or `OOMKilled`, and `RESTARTS` climbs. Placement is done. Something kills the container after it starts.

## Read the last terminated state

```bash
kubectl describe pod -n media -l app=media-buffer
```{{exec}}

In the container block, find `Last State:`:

```text
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
```

`OOMKilled`, exit code 137 (128 + signal 9, SIGKILL). The kernel's out-of-memory killer ended the container for going over its **memory limit**. The docs describe the mechanism: "`memory` limits are enforced by the kernel with out of memory (OOM) kills."

## Read the limit, and the QoS class

The same output holds both. In the container block:

- `Limits:` reads memory 48Mi.
- `Requests:` reads memory 32Mi.

Near the bottom, `QoS Class:` reads `Burstable`, because the request sits below the limit.

The container writes about 60Mi into a memory-backed volume at startup. The kernel charges that memory to the container. 60Mi is more than 48Mi, so the container dies on every start. The 32Mi request was small enough to schedule. The 48Mi limit is smaller than the container needs.

Next: raise the limit.
