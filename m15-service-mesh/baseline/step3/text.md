# Step 3 — Mesh-managed mTLS

The mesh gives every sidecar a short-lived X.509 identity (a SPIFFE identity tied to the pod's ServiceAccount) and can require that all pod-to-pod traffic be mutually authenticated with it. You turn that on with a **PeerAuthentication**. `media` has one in `STRICT` mode, so a meshed server accepts *only* Istio mTLS — plaintext is refused.

## Read the policy

```bash
kubectl get peerauthentication -n media -o yaml
```{{exec}}

`spec.mtls.mode: STRICT`, namespace-wide (no `selector`). Every server sidecar in `media` now demands mTLS on its inbound port.

## The mTLS path works (both ends in the mesh)

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

`HTTP 200`. `mesh-client`'s sidecar presents its client certificate, `session-broker`'s sidecar verifies it, and the request is allowed. Neither container ran TLS code — the proxies did it. You can see the issued certificate on the client:

```bash
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config secret "$POD" -n media
```{{exec}}

## The plaintext path is rejected

Now call `session-broker` from a pod that is **not** in the mesh — a throwaway client in `signaling` (never labeled for injection, so no sidecar, so plaintext on the wire):

```bash
kubectl run plain --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n signaling -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

It fails — the connection is reset / returns no `200`, because `session-broker`'s sidecar drops the unauthenticated plaintext. Same Service, same endpoints; the outcome is decided by whether the caller speaks mTLS.

## The instinct to build

STRICT mTLS is enforced by the **server's** sidecar. A caller gets in only if it too has a sidecar presenting a valid mesh identity. That single fact explains a whole class of "it worked from inside but not from that one pod" failures — the odd pod out isn't in the mesh.
