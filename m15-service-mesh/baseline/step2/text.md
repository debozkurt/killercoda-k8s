# Step 2 — Traffic management: routes, timeouts, retries

The mesh shapes L7 traffic with two objects. A **VirtualService** says *how* to route requests to a host (match, route, timeout, retries). A **DestinationRule** says *what* those destinations are (named subsets) and *how* to talk to them (mTLS, connection pool, circuit breaker). Both are applied by the **caller's** sidecar on the way out.

## Read the two objects

```bash
kubectl get virtualservice,destinationrule -n media
```{{exec}}

```bash
kubectl get virtualservice session-broker -n media -o yaml
```{{exec}}

Under `http:` — the route sends traffic to `subset: stable`, with `timeout: 3s` and `retries: { attempts: 2, ... }`. That's the platform enforcing a deadline and a retry budget for every caller of `session-broker`, no application code involved.

```bash
kubectl get destinationrule session-broker -n media -o yaml
```{{exec}}

`subsets:` defines `stable` (selects the running pods, `app: session-broker`) and `canary` (`version: canary`, none deployed yet). `trafficPolicy.outlierDetection` is the **circuit breaker** — eject a backend that returns `consecutive5xxErrors: 5` for `baseEjectionTime`.

## Drive a request from inside the mesh

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

`HTTP 200`. The request left `mesh-client`'s Envoy, matched the VirtualService, went to a `stable` pod, and came back within the timeout.

## See what Envoy compiled the rules into

```bash
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config routes "$POD" -n media --name 80 -o json | head -40
```{{exec}}

istiod translated the VirtualService and DestinationRule into Envoy **routes** and **clusters** and pushed them to the sidecar. The config you write is declarative; what actually moves packets is this compiled Envoy config — which is exactly what you'll read when a route misbehaves.

## The instinct to build

Retries, timeouts, and circuit breaking are mesh config, not app logic. The VirtualService and DestinationRule are the source; the caller's Envoy is the enforcer; `istioctl proxy-config` is how you confirm the two match.
