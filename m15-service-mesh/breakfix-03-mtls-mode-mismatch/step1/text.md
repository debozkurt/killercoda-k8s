# Step 1 — Diagnose the mTLS mismatch

Two `503` causes are already off the table if the pods are `2/2` and the route lands on endpoints. Confirm that, then read the two mTLS settings side by side.

## Reproduce, and rule out 01 and 02

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

`HTTP 503`. Now rule out the previous two scenarios:

```bash
kubectl get pods -n media
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config endpoints "$POD" -n media | grep 'session-broker' | grep ':80'
```{{exec}}

Every pod is `2/2` (so `session-broker` has a sidecar — not break/fix 01), and the `stable` cluster has endpoints on `:80` (so the route isn't landing on an empty subset — not break/fix 02). The workload and the route are both fine.

## Read both halves of mTLS

When the pod and the route check out, the remaining `503` cause is a transport mismatch. Read the server's requirement:

```bash
kubectl get peerauthentication default -n media -o yaml | grep -A2 mtls:
```{{exec}}

`mode: STRICT` — `session-broker`'s sidecar accepts **only** mTLS. Now the client's instruction:

```bash
kubectl get destinationrule session-broker -n media -o yaml | grep -A2 'tls:'
```{{exec}}

`mode: DISABLE` — callers are told to send **plaintext**. That's the contradiction: the client sends plaintext, the server accepts only mTLS, so the server's sidecar resets the connection and the caller gets `503`.

## Why this is subtle

Nothing is unhealthy, and each object looks reasonable on its own — you only see the bug by reading them *together*. Note too that with no DestinationRule `tls` block at all, Istio's *automatic* mTLS would have negotiated mTLS correctly here; the explicit `DISABLE` override is what forced the mismatch.
