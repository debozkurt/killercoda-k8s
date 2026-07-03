# Step 1 — Diagnose the 503 with istioctl

The pods are healthy this time, so `kubectl get pods` won't find the break. The route will. Reproduce, rule out the workload, then read what Envoy compiled.

## Reproduce the failure

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

`HTTP 503`.

## Rule out the workload

```bash
kubectl get pods -n media
kubectl get endpoints session-broker -n media
```{{exec}}

Every pod is `2/2`; `session-broker` has endpoints on `:80`. It's healthy and in the mesh — so this `503` is not the backend. (Contrast break/fix 01, where `session-broker` was `1/1`.)

## Follow the route in Envoy

The caller's sidecar is what routes the request. Ask it where `session-broker` traffic goes:

```bash
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config routes "$POD" -n media --name 80 -o json | grep -i '"cluster"'
```{{exec}}

The route's target cluster is `outbound|80|canary|session-broker.media.svc.cluster.local` — the **canary** subset. Now check that cluster's endpoints:

```bash
istioctl proxy-config endpoints "$POD" -n media | grep session-broker
```{{exec}}

The `|stable|` cluster lists healthy Pod IPs; the `|canary|` cluster is **empty**. The route points at a subset with no pods — no healthy upstream, hence `503`.

## Confirm the source

```bash
kubectl get virtualservice session-broker -n media -o yaml | grep -A3 route:
kubectl get pods -n media -l version=canary
```{{exec}}

The VirtualService routes to `subset: canary`, and there are no pods labeled `version: canary`. The DestinationRule defines the subset, but nobody ever deployed a canary to fill it. The intent (a canary rollout) got applied before the pods existed.
