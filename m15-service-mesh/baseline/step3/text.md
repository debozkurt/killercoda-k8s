# Step 3 — Mesh-managed mTLS

Each sidecar holds a short-lived certificate for its pod's ServiceAccount. A **PeerAuthentication** tells the server sidecars which traffic to accept. `media` has one in `STRICT` mode: a server sidecar accepts only Istio mTLS.

```bash
kubectl get peerauthentication -n media
```{{exec}}

The `MODE` column reads `STRICT`. The policy is named `default` and has no selector, so it covers every workload in `media`.

## The mTLS path works

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

HTTP 200. The `mesh-client` sidecar presented its certificate, and the `session-broker` sidecar verified it. Neither application ran TLS code. See the certificate on the client:

```bash
istioctl proxy-config secret deployment/mesh-client -n media
```{{exec}}

The `default` row is the workload certificate. `NOT AFTER` is about 24 hours after `NOT BEFORE`; the sidecar rotates it before it expires.

## The plaintext path is rejected

Call `session-broker` from a pod outside the mesh. The `signaling` namespace has no injection label, so this throwaway pod has no sidecar and sends plaintext:

```bash
kubectl run plain --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n signaling -- \
  curl -sS -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

The output reads `curl: (56) Recv failure: Connection reset by peer` and HTTP 000. The server's sidecar closed the connection. The caller has no Envoy of its own, so it gets a raw reset instead of an HTTP status. Read the server side:

```bash
kubectl logs -n media deploy/session-broker -c istio-proxy --tail=1
```{{exec}}

The line contains `NR filter_chain_not_found`: the `STRICT` sidecar has no filter chain for plaintext. Same Service, same endpoints. The result depends on whether the caller speaks mTLS.
