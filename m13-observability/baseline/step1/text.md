# Step 1 — Events: the control plane's own signal

An **Event** is an API object. The scheduler, the kubelet and the controllers create one when they act on another object. An Event is not a log line your app wrote.

## Generate events, then read them

A **Deployment** keeps a set of identical Pods running. Restart one and read what the control plane records:

```bash
kubectl rollout restart deployment session-broker -n media
sleep 8
kubectl events -n media | tail -10
```{{exec}}

`kubectl events` sorts by time, so the newest line is last. Read the columns:

```text
LAST SEEN   TYPE     REASON              OBJECT                       MESSAGE
8s          Normal   ScalingReplicaSet   deployment/session-broker    Scaled up replica set …
7s          Normal   Scheduled           pod/session-broker-…         Successfully assigned media/…
6s          Normal   Started             pod/session-broker-…         Started container nginx
```

Each Event has a `type` (Normal or Warning), a `reason` and the object it is about.

## Survey for trouble

Events belong to a namespace. Add `-A` to read every namespace, and filter on type:

```bash
kubectl events -A --types=Warning
```{{exec}}

A healthy fleet shows few lines or none. During triage this command finds trouble without knowing where it lives.

## Zoom to one object

```bash
kubectl events -n media --for deployment/session-broker
kubectl describe deployment session-broker -n media | tail -8
```{{exec}}

`--for` takes a kind and a name. `describe` prints the same events at the bottom of its output. A repeated event shows as x3 over 5m: the same event happened three times in five minutes. A climbing count marks an active problem.

## The older reader

```bash
kubectl get events -n media --field-selector reason=Started
```{{exec}}

`get events` does not sort and hides the count. Its `--field-selector` is useful: select on `reason`, `type` or `involvedObject.name`.

Events expire. The API server deletes each one after one hour by default. A failure that healed two hours ago leaves no events. On to logs.
