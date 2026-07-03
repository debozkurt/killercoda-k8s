# Step 2 — Fix it and verify

The policy is correct; the workload is out of compliance. Add the `limits` the rule requires, and the next Pod the ReplicaSet creates will pass admission.

## Add resource limits

Patch the container to declare CPU and memory limits:

```bash
kubectl patch deployment billing-api -n tenant-apps --type=json -p '[
  {"op":"add","path":"/spec/template/spec/containers/0/resources/limits",
   "value":{"cpu":"100m","memory":"64Mi"}}
]'
```{{exec}}

Or edit it in place — under the container's `resources`, add a `limits` block:

```bash
kubectl edit deployment billing-api -n tenant-apps
#   resources:
#     requests: { cpu: 25m, memory: 32Mi }
#     limits:   { cpu: 100m, memory: 64Mi }    # add this
```

The patch changes the Pod template, so the ReplicaSet rolls a new Pod — and this one satisfies `require-resource-limits`, so admission accepts it.

## Verify

```bash
kubectl rollout status deployment/billing-api -n tenant-apps --timeout=60s
kubectl get pods -n tenant-apps -l app=billing-api
```{{exec}}

`billing-api` goes to `1/1` and a Pod is finally `Running`. The rejection is gone because the object now complies — nothing about the policy changed. You fixed the workload, not the gate. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
