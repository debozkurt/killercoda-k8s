# Step 1 — Diagnose the validating denial

Same `0/N`-no-Pods shape as break/fix 01, but read the event: this is a real denial, not a failed call. The webhook was reached and rejected the Pod for a missing label — one the mutating webhook was supposed to add. The fix is upstream.

## Read the denial

```bash
kubectl get deploy,rs,pods -n tenant-apps -l app=orders-api
kubectl describe rs -n tenant-apps -l app=orders-api | sed -n '/Events/,$p'
```{{exec}}

`FailedCreate` / `Error creating: admission webhook "validate.admission-guard.polyphone.example" denied the request: admission-guard: object is missing required label 'env'`. This says **`denied the request`** — the validating webhook answered, and its answer was no: the Pod has no `env` label. Confirm the workload indeed sets none:

```bash
kubectl get deploy orders-api -n tenant-apps -o jsonpath='{.spec.template.metadata.labels}' ; echo
```{{exec}}

`app`, `plane`, `tier` — no `env`. But that's true in the baseline too, where the workload came up fine: the **mutating** webhook injects `env` before validation runs. So the question is why it didn't this time.

## Read why the mutating webhook didn't fire

The backend is healthy (this isn't break/fix 01), so read what the mutating webhook actually matches:

```bash
kubectl get mutatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].rules[0].operations}{"\n"}'
kubectl get validatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].rules[0].operations}{"\n"}'
```{{exec}}

The mutating webhook's `operations` is `["UPDATE"]`; the validating one is `["CREATE"]`. A Pod is **created** by its ReplicaSet, so the mutating webhook — matching only `UPDATE` — never fires, and `env` is never injected. Then the validating webhook, which *does* match `CREATE`, sees a Pod with no `env` and rejects it. The denial names validation; the fault is the mutating webhook's `operations`. Fix that, and mutation will supply what validation requires.
