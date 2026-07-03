# Step 1 — Diagnose the 0/1 with no Pods

A Deployment at `0/N` with no Pods means admission is rejecting the Pods its ReplicaSet creates. The reason is a `FailedCreate` event on the ReplicaSet. Find it, then read *how* it failed — a failed call is not a policy denial.

## Confirm: no Pods, and the reason is on the ReplicaSet

```bash
kubectl get deploy,rs,pods -n tenant-apps -l app=billing-api
```{{exec}}

The Deployment is `0/1`, the ReplicaSet `DESIRED 1 / CURRENT 0`, and there are no Pods. Nothing crashed — nothing was created. Read the ReplicaSet's events:

```bash
kubectl describe rs -n tenant-apps -l app=billing-api | sed -n '/Events/,$p'
```{{exec}}

A repeating `FailedCreate` / `Error creating: Internal error occurred: failed calling webhook "mutate.admission-guard.polyphone.example": failed to call webhook: … no endpoints available for service "admission-guard"`. Read that message precisely: it is **`failed calling webhook`**, not `denied the request`. The API server never got a verdict — it couldn't reach the webhook at all. That is an infrastructure failure, not a policy one.

## Why a failed call becomes a rejection

```bash
kubectl get pods,endpoints -n admission
kubectl get mutatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].failurePolicy}{"\n"}'
```{{exec}}

There are **no `admission-guard` Pods** and the Service has **no endpoints** — the backend is down. And the webhook's `failurePolicy` is `Fail`: when the API server can't complete the call, it fails *closed* and rejects the request. So a dead backend plus `Fail` blocks every Pod create in scope. (Note the blast radius held: this only hit `tenant-apps`, because the webhook is scoped there — the fleet kept running.) The fix isn't the workload; it's the backend.
