# Step 1 — Diagnose the failing calls

A `503` in a mesh has several causes. Walk the request path and let the evidence pick one.

## Reproduce the failure

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

`HTTP 503`. The caller reached its own Envoy but got no usable response from upstream.

## Rule out the Service layer

Is this an endpoints/DNS problem, like M04?

```bash
kubectl get endpoints session-broker -n media
kubectl exec -n media deploy/mesh-client -c curl -- nslookup session-broker.media
```{{exec}}

The Service has a Pod IP on `:80` and the name resolves. The backend exists. This isn't the Service layer.

## Count the containers

Now look at the pods in `media` — read the `READY` column carefully:

```bash
kubectl get pods -n media
```{{exec}}

`transcoder`, the `media-engine` pods, and `mesh-client` are `2/2`. `session-broker` is **`1/1`**. In a meshed namespace, `1/1` means no sidecar — this pod isn't in the mesh. Confirm from Istio's side:

```bash
istioctl proxy-status | grep session-broker
```{{exec}}

Nothing — a pod with no sidecar never registers with istiod. Read why the injector skipped it:

```bash
kubectl get pod -n media -l app=session-broker -o yaml | grep -A2 'annotations:'
```{{exec}}

There it is: `sidecar.istio.io/inject: "false"`. That pod-level annotation overrides the namespace's `istio-injection=enabled`, so `session-broker` was admitted without a proxy.

## Why the 503

`session-broker`'s app is healthy, but every caller's sidecar originates Istio mTLS to it (per the DestinationRule). With no sidecar on `session-broker` to terminate that mTLS, the caller's Envoy can't complete the connection and returns `503`. The fix isn't to touch mTLS — it's to put `session-broker` back in the mesh.
