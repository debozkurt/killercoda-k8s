# Step 1 — Diagnose the image rejection

Same `0/N`-no-Pods shape as breakfix-01, so the method is the same: read the ReplicaSet's `FailedCreate` denial. The difference is *which* policy fired — and here it's the image gate.

## Confirm the shape and read the denial

```bash
kubectl get deploy,rs,pods -n tenant-apps -l app=call-recorder
kubectl describe rs -n tenant-apps -l app=call-recorder | sed -n '/Events/,$p'
```{{exec}}

`0/1`, a ReplicaSet with `CURRENT 0`, no Pods — and a repeating `Error creating: admission webhook "validate.kyverno.svc-fail" denied the request:` naming the policy **`disallow-latest-tag`** and its message about the `:latest` tag. Note the policy name in the denial: this is the image rule, not `require-resource-limits`. Reading *which* policy failed is how you tell the two `0/N` scenarios apart at a glance.

## Read the offending image

```bash
kubectl get deploy call-recorder -n tenant-apps \
  -o jsonpath='{.spec.template.spec.containers[0].image}' ; echo
kubectl get clusterpolicy disallow-latest-tag -o yaml | grep -A6 'validate:'
```{{exec}}

The image is `nginx:latest`; the rule requires it to *not* match `*:latest` (`!*:latest`). The Deployment sets `limits` (so `require-resource-limits` is satisfied) — the only violation is the tag. That `:latest` is exactly what the supply-chain policy exists to stop: a tag that can silently change what runs. The fix is to pin it.
