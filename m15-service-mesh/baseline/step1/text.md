# Step 1 — The sidecar: how a pod joins the mesh

A pod is "in the mesh" when it carries an Envoy sidecar. Istio injects that sidecar automatically for any pod created in a namespace labeled `istio-injection=enabled`. The `media` namespace was labeled before its workloads booted, so they all got one.

## See the injection label and the meshed pods

```bash
kubectl get namespace media --show-labels
```{{exec}}

`istio-injection=enabled` is present. Now the pods:

```bash
kubectl get pods -n media
```{{exec}}

`session-broker`, `transcoder`, the `media-engine` replicas, and `mesh-client` all read **`2/2`** — two containers, not one. Compare a namespace that was never labeled:

```bash
kubectl get pods -n signaling
```{{exec}}

Those are `1/1`. Same image, no mesh — the difference is the injected proxy.

## Look inside a meshed pod

```bash
kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].spec.containers[*].name}{"\n"}'
```{{exec}}

Two containers: `app` and `istio-proxy`. The `istio-proxy` is Envoy. An init container (`istio-init`) also ran first — it programmed iptables rules that redirect the pod's inbound and outbound traffic through Envoy, which is how the proxy intercepts everything transparently without the app knowing.

## See the pod from Istio's side

```bash
istioctl proxy-status
```{{exec}}

Every sidecar shows up here with its config-sync columns (`CDS`, `LDS`, `EDS`, `RDS`) reading `SYNCED` — meaning Envoy has the current clusters, listeners, endpoints, and routes from istiod. A pod with no sidecar never appears in this list; that absence is the first thing to check when a workload isn't behaving like a mesh member.

## The instinct to build

Mesh membership is per-pod and decided at admission time. `2/2` and a line in `proxy-status` mean "this pod's traffic goes through Envoy, so mesh policy applies to it." `1/1` means it doesn't — and no amount of VirtualService or mTLS config will touch it.
