# Step 2 — Fix it and verify

The webhook's logic is fine; its *scope* is wrong. Narrow the `namespaceSelector` back to the label that means "governed" — `admission-guard=enabled`, which only `tenant-apps` carries — so the webhook stops touching every other namespace.

## Narrow the namespaceSelector

```bash
kubectl patch validatingwebhookconfiguration admission-guard --type=json \
  -p '[{"op":"replace","path":"/webhooks/0/namespaceSelector","value":{"matchLabels":{"admission-guard":"enabled"}}}]'
```{{exec}}

Confirm the scope is back to `tenant-apps` only:

```bash
kubectl get validatingwebhookconfiguration admission-guard \
  -o jsonpath='{.webhooks[0].namespaceSelector}{"\n"}'
```{{exec}}

## Re-admit sip-canary

`signaling` is no longer intercepted, so its Pods pass straight through. Trigger a fresh attempt:

```bash
kubectl rollout restart deployment/sip-canary -n signaling
kubectl rollout status  deployment/sip-canary -n signaling --timeout=90s
kubectl get pods -n signaling -l app=sip-canary
```{{exec}}

`sip-canary` goes to `1/1` — the webhook no longer sees `signaling`, so there's no `env` requirement to fail. Note `tenant-apps` is still governed exactly as before; you didn't weaken the policy, you *scoped* it. You fixed the webhook's `namespaceSelector`, not the workload. For the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
