# Step 2 — Fix it and verify

The `stable` subset has the running pods; the route just needs to point there. Two honest fixes exist — send traffic to `stable`, or actually deploy the canary. Since no canary build exists, route back to `stable`.

## Point the route at a subset that has pods

```bash
kubectl patch virtualservice session-broker -n media --type=json \
  -p '[{"op":"replace","path":"/spec/http/0/route/0/destination/subset","value":"stable"}]'
```{{exec}}

(Or `kubectl edit virtualservice session-broker -n media` and change `subset: canary` to `subset: stable`.) istiod recompiles the route to target the `stable` cluster and pushes it to every caller's sidecar within a second or two.

## Confirm Envoy re-pointed the route

```bash
POD=$(kubectl get pod -n media -l app=mesh-client -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config routes "$POD" -n media --name 80 -o json | grep -i '"cluster"'
```{{exec}}

The route's cluster is now `outbound|80|stable|session-broker.media.svc.cluster.local` — a cluster with endpoints.

## Verify the calls succeed

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

`HTTP 200`. The route now lands on live pods. For self-grading and the full path, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
