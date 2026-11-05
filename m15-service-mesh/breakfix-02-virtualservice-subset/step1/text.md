# Step 1 — Diagnose the 503

## Reproduce and read the caller's log

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -w "\nHTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

HTTP 503 with the body `no healthy upstream`.

```bash
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1
```{{exec}}

The line reads `503 UH no_healthy_upstream`. `UH` means the chosen cluster had no healthy endpoint. Read the cluster at the end of the line: `outbound|80|canary|session-broker.media.svc.cluster.local`. The route sent the request to the `canary` subset.

## Rule out the workload

```bash
kubectl get pods -n media
```{{exec}}

Every pod is 2/2, including `session-broker`. The server is healthy and in the mesh.

## Read the route and the subset

```bash
kubectl describe virtualservice session-broker -n media
```{{exec}}

Under `Route:` → `Destination:`, read `Subset:  canary`.

```bash
kubectl get destinationrule session-broker -n media -o yaml
```{{exec}}

Under `subsets:`, `canary` selects `version: canary`. Look for pods with that label:

```bash
kubectl get pods -n media -l version=canary
```{{exec}}

`No resources found`. Confirm what Envoy holds for that cluster:

```bash
istioctl proxy-config endpoints deployment/mesh-client -n media \
  --cluster "outbound|80|canary|session-broker.media.svc.cluster.local"
```{{exec}}

Only the header row. The cluster exists and has no endpoints. The route is valid; it points at an empty group.
