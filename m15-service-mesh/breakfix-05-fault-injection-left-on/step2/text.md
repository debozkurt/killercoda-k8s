# Step 2 — Fix it and verify

Remove the `fault` block from the route. Keep the timeout and retries.

```bash
kubectl patch virtualservice session-broker -n media --type=json \
  -p '[{"op":"remove","path":"/spec/http/0/fault"}]'
```{{exec}}

## Verify

```bash
kubectl exec -n media deploy/mesh-client -c curl -- sh -c \
  'for i in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null -w "%{http_code} " --max-time 5 http://session-broker.media/; done; echo'
```{{exec}}

Ten 200 responses. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m15-service-mesh/ANSWER-KEY.md).
