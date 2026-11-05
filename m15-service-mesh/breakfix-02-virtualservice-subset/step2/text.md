# Step 2 — Fix it and verify

No canary build exists, so route traffic back to the `stable` subset, which selects the running pods.

```bash
kubectl patch virtualservice session-broker -n media --type=json \
  -p '[{"op":"replace","path":"/spec/http/0/route/0/destination/subset","value":"stable"}]'
```{{exec}}

`istiod` compiles the new route and pushes it to every caller sidecar within seconds.

## Verify

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
sleep 2
kubectl logs -n media deploy/mesh-client -c istio-proxy --tail=1
```{{exec}}

HTTP 200, and the log line now names `outbound|80|stable|session-broker.media.svc.cluster.local` with no response flag. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m15-service-mesh/ANSWER-KEY.md).
