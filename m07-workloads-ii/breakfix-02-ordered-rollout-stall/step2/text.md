# Step 2 — Fix it and verify

The fix has two parts, and the second one surprises people. Correcting the template does not repair the Pod that already runs the bad one.

## Correct the probe's port

```bash
kubectl patch statefulset session-store -n app-services --type=json -p \
  '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'
```{{exec}}

Wait 20 seconds for the controller to react, then check:

```bash
kubectl rollout status statefulset/session-store -n app-services --timeout=20s
kubectl get pods -n app-services -l app=session-store
```{{exec}}

The status command times out, and that is expected. `session-store-0` is still `0/1`, and its `AGE` has not changed. The controller did not replace it. The docs warn about this case: with `OrderedReady`, "it's possible to get into a broken state that requires manual intervention to repair." The controller waits for every Pod it created to be Ready before it acts on any ordinal. That wait includes the replacement of the broken Pod.

## Delete the Pod that runs the bad template

```bash
kubectl delete pod session-store-0 -n app-services
```{{exec}}

The controller recreates `session-store-0` from the corrected template. The new Pod keeps its name and its claim. Watch the set unblock:

```bash
kubectl rollout status statefulset/session-store -n app-services --timeout=120s
```{{exec}}

Once ordinal 0 is Ready, the controller creates ordinal 1, then ordinal 2. Confirm:

```bash
kubectl get statefulset session-store -n app-services
kubectl get pods -n app-services -l app=session-store
```{{exec}}

`READY 3/3`, and all three Pods are `1/1`. The two missing Pods were a symptom. The fault sat at ordinal 0. See [`ANSWER-KEY.md`](../ANSWER-KEY.md) for self-grading, then `finish.md`.
