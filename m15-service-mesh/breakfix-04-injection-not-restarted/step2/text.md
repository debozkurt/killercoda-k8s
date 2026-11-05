# Step 2 — Fix it and verify

Recreate the caller's pod so that the webhook admits it with a sidecar. Do not change the PeerAuthentication in `media`.

```bash
kubectl rollout restart deployment session-dialer -n signaling
kubectl rollout status deployment session-dialer -n signaling
kubectl get pods -n signaling -l app=session-dialer
```{{exec}}

The new pod reads 2/2.

## Verify

```bash
kubectl exec -n signaling deploy/session-dialer -- \
  curl -sS -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

HTTP 200. The caller's sidecar now sends Istio mTLS, and the server's `STRICT` sidecar accepts it. (`kubectl exec` picks the `curl` container by default; Istio sets the pod's default-container annotation.)

The other `signaling` pods are still 1/1. In production, restart every Deployment in a newly enrolled namespace, in a controlled order. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m15-service-mesh/ANSWER-KEY.md).
