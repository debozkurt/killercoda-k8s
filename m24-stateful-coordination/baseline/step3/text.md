# Step 3 — Ordered, sequential lifecycle

A Deployment starts all its Pods at once. A StatefulSet, by default, does not: with **`podManagementPolicy: OrderedReady`** it brings replicas up one at a time, and each waits for the one before it to be Running **and** Ready. That ordering matters for workloads where member 0 must bootstrap the cluster before member 1 can join.

## Read the policy

```bash
kubectl get statefulset session-cache -n media \
  -o jsonpath='{.spec.podManagementPolicy}{"\n"}'
```{{exec}}

`OrderedReady` — the default. The guarantee: on scale-up, ordinal N+1 is not created until ordinal N is Ready; on scale-down, the highest ordinal is removed first. (The alternative, `Parallel`, drops the ordering and acts on all Pods at once — faster, but only safe when members don't depend on each other.)

## Watch the ordering, and identity survive

Scale down by one — the **highest** ordinal goes first:

```bash
kubectl scale statefulset session-cache -n media --replicas=2
kubectl get pods -n media -l app=session-cache
```{{exec}}

`session-cache-2` is terminating; `-0` and `-1` are untouched. Its PVC stays behind — a StatefulSet does not delete `data-session-cache-2` on scale-down, so the member's cache is preserved for when it returns. Confirm:

```bash
kubectl get pvc -n media -l app=session-cache
```{{exec}}

`data-session-cache-2` is still `Bound`. Now scale back up:

```bash
kubectl scale statefulset session-cache -n media --replicas=3
kubectl rollout status statefulset session-cache -n media --timeout=90s
```{{exec}}

The new Pod comes back as `session-cache-2` — same ordinal identity — and re-mounts the *same* `data-session-cache-2` PVC it had before. Stable name, sticky storage, ordered lifecycle: a member can leave and rejoin as itself. That's the property leader-election and clustering protocols rely on. Next: how the members agree on who leads.
