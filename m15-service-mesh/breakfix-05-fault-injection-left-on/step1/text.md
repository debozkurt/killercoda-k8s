# Step 1 — Diagnose the partial 503

## Measure the failure

```bash
kubectl exec -n media deploy/mesh-client -c curl -- sh -c \
  'for i in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null -w "%{http_code} " --max-time 5 http://session-broker.media/; done; echo'
```{{exec}}

A mix of 200 and 503, about half each. Look at one failure:

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -w "\nHTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

Run it until it prints HTTP 503. The body reads `fault filter abort`.

## Read both sidecars

```bash
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=10
```{{exec}}

The 503 lines carry the flag `FI` and the detail `fault_filter_abort`. Their upstream host field is `-`: the request never left the caller's pod.

```bash
kubectl logs -n media deploy/session-broker -c istio-proxy --tail=10
```{{exec}}

Every request line reads 200; the other lines are sidecar startup messages. The server never saw the failed requests, so its logs have no errors.

## Find the fault

A fault is part of a VirtualService route, and the caller's sidecar applies it:

```bash
kubectl describe virtualservice session-broker -n media
```{{exec}}

Under `Http:`, read the `Fault:` block: `Abort:` with `Http Status:  503` and `Percentage:` → `Value:  50`. The resilience test left it in the route. Retries do not repeat an injected abort, so half the calls fail.
