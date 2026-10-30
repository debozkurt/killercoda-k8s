# Step 1 — Diagnose the halted rollout

A StatefulSet update replaces Pods one at a time, from the highest ordinal down. A halted update leaves the set split across two revisions. Find the split.

## The rollout does not finish

```bash
kubectl rollout status statefulset/session-store -n app-services --timeout=15s
```{{exec}}

The command waits for a Pod to become Ready, then times out. The timeout is the expected result here.

## Two revisions in one set

Each StatefulSet Pod carries a `controller-revision-hash` label. Pods on the same template share the value:

```bash
kubectl get pods -n app-services -l app=session-store -L controller-revision-hash
```{{exec}}

`session-store-0` and `session-store-1` are `Running` and share one hash. `session-store-2` has a different hash and is in `ErrImagePull` or `ImagePullBackOff`. The controller replaced the highest ordinal first. That Pod never became Ready, so the controller stopped. Ordinals 0 and 1 never left the old revision, and they still serve.

## Why the new Pod fails

```bash
kubectl describe pod session-store-2 -n app-services
```{{exec}}

The `Image:` line reads nginx:1.25.99. The `Events:` block shows `Failed to pull image` with a `not found` error. The release named a tag that does not exist. Compare the Pod that still works:

```bash
kubectl describe pod session-store-0 -n app-services | grep Image:
```{{exec}}

The old Pods run nginx:1.25. Next: undo the release, then see whether that alone repairs ordinal 2.
