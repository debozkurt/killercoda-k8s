# Step 1 — Diagnose the 503

## Reproduce from the in-mesh client

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -w "\nHTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

HTTP 503, with a body that starts `upstream connect error or disconnect/reset before headers` and ends with a `TLS_error` reason. The caller's Envoy answered; it could not finish a TLS handshake with the server.

## Read the caller's access log

```bash
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1
```{{exec}}

Read three fields:

- `503 URX,UF`: upstream connection failure (`UF`), after the retry limit (`URX`)
- `WRONG_VERSION_NUMBER`: the far end did not answer in TLS
- the upstream address: the request reached the pod IP on port 80

The client sent Istio mTLS, and something that does not speak TLS answered. A meshed server terminates mTLS in its sidecar. Check whether the server has one.

## Count the containers

```bash
kubectl get pods -n media
```{{exec}}

`mesh-client` reads 2/2. `session-broker` reads 1/1: no sidecar. Confirm from Istio's side:

```bash
istioctl proxy-status
```{{exec}}

There is no `session-broker` row. A pod without a sidecar never connects to `istiod`.

## Find why the injector skipped it

The namespace has `istio-injection=enabled`, so look at the pod's own labels:

```bash
kubectl get pods -n media -l app=session-broker --show-labels
```{{exec}}

The labels include `sidecar.istio.io/inject=false`. That pod label overrides the namespace label, so the webhook admitted the pod without a proxy. The DestinationRule still tells every caller to send `ISTIO_MUTUAL` mTLS, and plain nginx receives it.
