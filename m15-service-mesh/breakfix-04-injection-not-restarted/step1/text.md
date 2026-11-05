# Step 1 — Diagnose the reset

## Reproduce from the failing caller

```bash
kubectl exec -n signaling deploy/session-dialer -- \
  curl -sS -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

`curl: (56) Recv failure: Connection reset by peer` and HTTP 000. There is no 503 and no Envoy body. Compare a caller in `media`:

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

HTTP 200. The server works for meshed callers.

## Read the server's log

```bash
kubectl logs -n media deploy/session-broker -c istio-proxy --tail=1
```{{exec}}

`NR filter_chain_not_found`: the server's `STRICT` sidecar received plaintext and closed the connection. A meshed caller would have sent mTLS. A caller with a sidecar would also have turned the closed connection into a 503. The raw reset says the caller has no Envoy.

## Check the caller's membership

```bash
kubectl get pods -n signaling
```{{exec}}

`session-dialer` reads 1/1, like every other pod in `signaling`.

```bash
kubectl get namespace signaling --show-labels
```{{exec}}

The namespace has `istio-injection=enabled`. The label is correct, and the pods have no sidecar. Injection happens only when a pod is created. Every pod in `signaling` started before the label was added, and nothing recreated them.
