# Step 1 — The sidecar: how a pod joins the mesh

A pod is in the mesh when it runs an Envoy sidecar. Istio adds the sidecar with a mutating admission webhook (a webhook that changes an object before the API server stores it). The webhook acts on new pods in a namespace labeled `istio-injection=enabled`.

```bash
kubectl get namespace media --show-labels
```{{exec}}

The `LABELS` column includes `istio-injection=enabled`.

```bash
kubectl get pods -n media
```{{exec}}

Each pod reads 2/2 in the `READY` column: the application container plus the sidecar. Compare a namespace without the label:

```bash
kubectl get pods -n signaling
```{{exec}}

Those pods read 1/1. Same images, no sidecar.

## Look inside a meshed pod

```bash
kubectl describe pod -n media -l app=session-broker
```{{exec}}

Read the two container sections near the top:

- `Init Containers:` lists `istio-init`. It ran first and installed iptables rules that send the pod's inbound and outbound TCP through Envoy.
- `Containers:` lists `app` (nginx, unchanged) and `istio-proxy` (Envoy).

The application does not know about the proxy. The kernel redirects its traffic.

## See the pod from Istio's side

```bash
istioctl proxy-status
```{{exec}}

Each sidecar has one row. The `CDS`, `LDS`, `EDS`, and `RDS` columns (clusters, listeners, endpoints, routes) read `SYNCED` with an age, for example `SYNCED (12s)`: Envoy has the latest configuration from `istiod`. `ECDS` reads `IGNORED` because these sidecars use no extension configuration. A pod without a sidecar has no row.

Mesh membership is per pod and fixed at creation. 2/2 and a row in `proxy-status` mean that mesh rules apply to the pod. 1/1 means that no mesh rule applies.
