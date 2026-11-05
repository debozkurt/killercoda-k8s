# Step 2 — Fix it and verify

`STRICT` is the required posture. Fix the client side. A change of the server to `PERMISSIVE` also stops the 503, but it makes the hop accept plaintext.

```bash
kubectl patch destinationrule session-broker -n media --type=json \
  -p '[{"op":"replace","path":"/spec/trafficPolicy/tls/mode","value":"ISTIO_MUTUAL"}]'
```{{exec}}

(Removing the `tls` block also works. Automatic mTLS then sends mTLS to any destination that has a sidecar.)

## Verify

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
kubectl get peerauthentication -n media
```{{exec}}

HTTP 200, and `MODE` still reads `STRICT`. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m15-service-mesh/ANSWER-KEY.md).
