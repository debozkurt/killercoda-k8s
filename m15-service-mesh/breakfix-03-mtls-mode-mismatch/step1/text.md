# Step 1 — Diagnose the 503

## Reproduce and read the caller's log

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -w "\nHTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

HTTP 503 with the body `upstream connect error or disconnect/reset before headers. retried and the latest reset reason: connection termination`.

```bash
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1
```{{exec}}

The line reads `503 URX,UC` and names the `stable` cluster with a pod IP as the upstream. `UC` means the upstream closed the connection. The route and the endpoint are fine: the request reached the server pod, and the server dropped it.

## Read the server's log

```bash
kubectl logs -n media deploy/session-broker -c istio-proxy --tail=3
```{{exec}}

Three lines with `NR filter_chain_not_found`, one per attempt (the first try and two retries). The server's sidecar had no filter chain for what the client sent.

## Read both sides of mTLS

The server side:

```bash
kubectl get peerauthentication -n media
```{{exec}}

`MODE` reads `STRICT`: the server sidecar accepts only Istio mTLS. The client side:

```bash
kubectl describe destinationrule session-broker -n media
```{{exec}}

Under `Traffic Policy:` → `Tls:`, read `Mode:  DISABLE`. Every caller sidecar sends plaintext to `session-broker`. Plaintext into a `STRICT` server matches no filter chain, so the server closes the connection.
