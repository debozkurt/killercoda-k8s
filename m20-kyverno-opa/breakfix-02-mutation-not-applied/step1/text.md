# Step 1 — Diagnose the missing label

The workload is healthy; a default is missing. Confirm the absence, then read the mutate policy's `match` against the Pod it was supposed to select.

## Confirm: healthy Pod, no owner label

```bash
kubectl get pods -n tenant-apps -L owner
```{{exec}}

`tenant-portal`'s Pod is `Running` but its `OWNER` column is empty. Nothing is broken about the workload — it just never got the label. Confirm the mutate policy exists and is Ready:

```bash
kubectl get clusterpolicy add-owner-label
```{{exec}}

`READY: true` — the policy is installed and its webhook is registered. So the engine is working; the question is why this Pod wasn't selected.

## Read the rule's match against the Pod

```bash
kubectl get clusterpolicy add-owner-label -o yaml | grep -A10 'match:'
kubectl get pod -n tenant-apps -l app=tenant-portal -o jsonpath='{.items[0].metadata.namespace}' ; echo
```{{exec}}

The rule's `match` names `namespaces: [tenant-app]` — but the Pod lives in `tenant-apps` (with an `s`). The selector doesn't match, so the mutate rule never fired on this Pod. It's a one-character typo in the policy's scope, and it fails *silently*: a mutation that doesn't match simply does nothing — no error, no event, just an absent field.

This is the opposite of breakfix-01. There the fix was the workload; here the workload is fine and the **policy** is wrong. Fix the `match`.
