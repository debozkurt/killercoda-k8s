# Step 2 — Fix it and verify

The validating webhook is correct; the mutating one matches the wrong operation. Restore `CREATE` so mutation fires when a Pod is created — before validation checks for the label it injects.

## Fix the mutating webhook's operations

```bash
kubectl patch mutatingwebhookconfiguration admission-guard --type=json \
  -p '[{"op":"replace","path":"/webhooks/0/rules/0/operations","value":["CREATE"]}]'
```{{exec}}

Confirm it now matches Pod creates:

```bash
kubectl get mutatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].rules[0].operations}{"\n"}'
```{{exec}}

## Re-admit orders-api

Admission runs on the *next* Pod create, so trigger one — the running Pods (there are none here) would never be mutated retroactively anyway:

```bash
kubectl rollout restart deployment/orders-api -n tenant-apps
kubectl rollout status  deployment/orders-api -n tenant-apps --timeout=90s
kubectl get pods -n tenant-apps -l app=orders-api -L env
```{{exec}}

`orders-api` goes to `1/1`, and its Pod now carries `env=tenant` — the mutating webhook fired on CREATE, injected the label, and the validating webhook admitted it. Mutate supplies what validate requires, in that order. You fixed the *mutating* configuration, not the workload and not the validating rule. For the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
