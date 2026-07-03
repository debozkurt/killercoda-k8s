# Step 2 — Validation admits the compliant, rejects the rest

A `validate` rule checks an object and, with `failureAction: Enforce`, blocks it if it fails. `tenant-web` complies, so it was admitted; anything that doesn't is denied at admission. See both sides.

## The compliant workload is up

```bash
kubectl get deploy -n tenant-apps
kubectl get pods -n tenant-apps
```{{exec}}

`tenant-web` is `1/1` and its Pod is `Running`. It declares CPU and memory limits, so `require-resource-limits` admitted it. Read the rule it satisfied:

```bash
kubectl get clusterpolicy require-resource-limits -o yaml | grep -A15 'rules:'
```{{exec}}

The rule matches Pods in `tenant-apps` and requires `resources.limits.memory` and `.cpu` to be non-empty (`?*`). `failureAction: Enforce` means a violation is rejected, not just logged.

## A non-compliant Pod is denied

Try to create a Pod with no limits. `--dry-run=server` runs the admission webhooks without persisting anything:

```bash
kubectl run bad --image=nginx:1.25 -n tenant-apps --restart=Never --dry-run=server
```{{exec}}

`Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:` — the message names the policy (`require-resource-limits`) and the rule, then repeats your `message`. That's the signature to recognize: not a workload bug, a policy rejecting the object. Every field you need to find the rule is in the string.
