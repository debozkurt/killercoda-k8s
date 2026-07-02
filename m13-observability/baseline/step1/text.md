# Step 1 — Events: the control plane's own signal

An **Event** isn't a log line your app wrote — it's the control plane (scheduler, kubelet, controllers) narrating what it *did* to an object.

## Generate some fresh events, then read them

```bash
kubectl rollout restart deployment session-broker -n media
sleep 6
kubectl get events -n media --sort-by=.lastTimestamp | tail -8
```{{exec}}

A rollout produces the Normal lifecycle beats — `Scheduled`, `Pulled`, `Created`, `Started`. Always add `--sort-by=.lastTimestamp`: `get events` is **unsorted** by default and you'll misread the order without it.

## Read the columns as fields

```text
LAST SEEN   TYPE     REASON      OBJECT                        MESSAGE
12s         Normal   Scheduled   pod/session-broker-…          Successfully assigned media/…
11s         Normal   Pulled      pod/session-broker-…          Container image "nginx:1.25" already present
```

Each event is a structured object: `type` (`Normal` or `Warning`), `reason` (the machine token), the `involvedObject` it's about, and a `count`/`lastTimestamp` (repeated identical events collapse into one row with a climbing `count`).

## Survey the stream by field

```bash
kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp | tail -10
```{{exec}}

On a healthy fleet this is short or empty — that's the point. In triage, filtering to `type=Warning` cluster-wide (`-A`) is how you find trouble without knowing where it lives. You can also select on `reason` (e.g. `--field-selector reason=BackOff`).

## `describe` aggregates events for one object

```bash
kubectl describe pod -n media -l app=session-broker | sed -n '/Events:/,$p'
```{{exec}}

`describe` finds an object's events by matching `involvedObject` to its UID — the move when you already know the suspect. `get events` surveys the neighborhood; `describe` zooms to one object.

One property to remember: events are **ephemeral**. The API server garbage-collects them after a TTL (~1 hour), so a failure that recovered two hours ago leaves no events behind. On to logs.
