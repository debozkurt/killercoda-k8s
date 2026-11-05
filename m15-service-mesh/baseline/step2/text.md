# Step 2 — Traffic management: routes, timeouts, retries

A **VirtualService** decides where a request to a host goes, and adds a timeout and retries. A **DestinationRule** defines the destination's subsets (label-selected groups of pods) and how a caller talks to them. The caller's sidecar applies both objects.

```bash
kubectl describe virtualservice session-broker -n media
```{{exec}}

Under `Spec:` → `Http:`, read `Subset:  stable`, `Timeout:  3s`, and the `Retries:` block with `Attempts:  2`. Every caller of `session-broker` gets this deadline and retry budget with no application code.

```bash
kubectl get destinationrule session-broker -n media -o yaml
```{{exec}}

Read `subsets:`. The `stable` subset selects `app: session-broker`. The `canary` subset selects `version: canary`, which no pod carries yet. `outlierDetection` is the circuit breaker: it ejects a pod after `consecutive5xxErrors: 5`. `tls.mode: ISTIO_MUTUAL` tells callers to send Istio mTLS.

(The YAML is used here instead of `describe` because `describe` capitalizes label keys, and subset labels must match pod labels exactly.)

## Send a request through the mesh

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

HTTP 200. Now read the line that the caller's sidecar logged for that request. The sidecar flushes its log about once per second, so wait a moment after the call:

```bash
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1
```{{exec}}

The line shows `"GET / HTTP/1.1" 200`, a dash where a response flag would be, and the upstream cluster `outbound|80|stable|session-broker.media.svc.cluster.local`. The cluster name carries the port, the subset, and the host. When a request fails, this line names why.

## See the compiled route

```bash
istioctl proxy-config routes deployment/mesh-client -n media --name 80
```{{exec}}

The `VIRTUAL SERVICE` column reads `session-broker.media`. `istiod` compiled your VirtualService into an Envoy route on the caller's sidecar. The object states intent; the route is what Envoy runs.
