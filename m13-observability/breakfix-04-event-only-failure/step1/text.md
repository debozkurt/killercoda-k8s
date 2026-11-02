# Step 1 — Find the cause in the events

A Pod that never starts has no logs. The control plane still records why, as an Event. Events belong to a namespace, so you search every namespace.

## The default namespace is empty

```bash
kubectl events
```{{exec}}

It reports that no events exist in the default namespace. `kubectl events` reads one namespace, the current one. The failure is elsewhere.

## Survey every namespace

```bash
kubectl events -A --types=Warning
```{{exec}}

```text
NAMESPACE      LAST SEEN         TYPE      REASON        OBJECT                  MESSAGE
call-routing   40s (x6 over 2m)  Warning   FailedMount   pod/rate-loader-…       MountVolume.SetUp failed for volume "rates" : configmap "rate-table-v2" not found
```

Look for a Pod stuck on a volume. The reason is FailedMount, the object is a Pod in call-routing, and the count is above 1: the kubelet retries and fails again. The message names the volume and the missing ConfigMap.

## Confirm with the Pod itself

```bash
kubectl get pods -n call-routing -l app=rate-loader
kubectl logs -n call-routing deploy/rate-loader
```{{exec}}

The Pod reads ContainerCreating. The log read fails with `waiting to start: ContainerCreating`. No container exists to log. The kubelet cannot start the container until it mounts every volume.

```bash
kubectl describe pod -n call-routing -l app=rate-loader | tail -8
```{{exec}}

`describe` prints the same FailedMount event at the bottom. Now find which ConfigMaps exist:

```bash
kubectl get configmap -n call-routing
```{{exec}}

The namespace holds `rate-table`. The Pod asks for `rate-table-v2`. A name mismatch blocks the mount, and the mount blocks the container. On to the fix.
