# Step 1 — Diagnose the 0/1 with no Pods

A Deployment at `0/N` with no Pods means admission is rejecting the Pods its ReplicaSet creates. The reason is a `FailedCreate` event on the ReplicaSet. Find it, then read which policy said no.

## Confirm: no Pods, and the reason is on the ReplicaSet

```bash
kubectl get deploy,rs,pods -n tenant-apps -l app=billing-api
```{{exec}}

The Deployment is `0/1`, the ReplicaSet `DESIRED 1 / CURRENT 0`, and there are no Pods. Nothing crashed — nothing was ever created. Read the ReplicaSet's events:

```bash
kubectl describe rs -n tenant-apps -l app=billing-api | sed -n '/Events/,$p'
```{{exec}}

A repeating `FailedCreate` / `Error creating: admission webhook "validate.kyverno.svc-fail" denied the request:` — and the body names the policy `require-resource-limits` and the rule, then your message: *"Resource limits (cpu and memory) are required for tenant workloads."* That's the whole diagnosis: a Kyverno validate policy is rejecting the Pod.

## Read the rule against the workload

```bash
kubectl get clusterpolicy require-resource-limits -o yaml | grep -A15 'rules:'
kubectl get deploy billing-api -n tenant-apps -o jsonpath='{.spec.template.spec.containers[0].resources}' ; echo
```{{exec}}

The rule requires `resources.limits.memory` and `.cpu` (`?*` = non-empty). The workload sets only `requests` — no `limits` block at all. That's the violation. The image is `nginx:1.25` (tagged), so `disallow-latest-tag` is satisfied; the *only* problem is the missing limits. On to the fix — and note the fix is the *workload*, not the policy: the policy is doing exactly its job.
