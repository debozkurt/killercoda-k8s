# Step 1 — Diagnose a denial in the wrong namespace

The denial reads like break/fix 02 — a missing `env` label — but it's landing in `signaling`, a namespace this webhook was never meant to govern. The tell isn't the message; it's *where* it fires. Read the webhook's scope.

## Read the denial, and note the namespace

```bash
kubectl get deploy,rs,pods -n signaling -l app=sip-canary
kubectl describe rs -n signaling -l app=sip-canary | sed -n '/Events/,$p'
```{{exec}}

`FailedCreate` / `admission webhook "validate.admission-guard.polyphone.example" denied the request: … object is missing required label 'env'`. A real denial — but in **`signaling`**. `admission-guard` governs `tenant-apps`; `signaling` runs fleet workloads that never carried an `env` label and were running fine a moment ago. A tenant webhook rejecting a `signaling` Pod is the symptom of a scope that's too wide.

## Read the webhook's scope

```bash
kubectl get validatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].namespaceSelector}{"\n"}'
kubectl get mutatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].namespaceSelector}{"\n"}'
```{{exec}}

The validating webhook's `namespaceSelector` is **`{}`** — an empty selector matches *every* namespace, so it now intercepts Pod creates cluster-wide. The mutating webhook is still correctly scoped to `admission-guard=enabled` (tenant-apps only), so it never injects `env` in `signaling` — and the over-broad validating webhook rejects the un-injected Pod. That also explains why `tenant-web` in `tenant-apps` is fine (mutate injects `env` there) while `signaling` is collateral damage. The fix is to narrow the validating webhook back to the namespaces it should govern.
