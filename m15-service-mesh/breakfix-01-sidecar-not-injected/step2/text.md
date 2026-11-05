# Step 2 — Fix it and verify

Do not change the PeerAuthentication or the DestinationRule. They are correct. Put `session-broker` back in the mesh.

## Remove the opt-out

The label lives in the Deployment's pod template. A merge patch with `null` deletes the key, and the template change starts a rollout:

```bash
kubectl patch deployment session-broker -n media \
  -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject":null}}}}}'
kubectl rollout status deployment session-broker -n media
```{{exec}}

The webhook admits the replacement pod with a sidecar.

## Confirm membership

```bash
kubectl get pods -n media -l app=session-broker
istioctl proxy-status
```{{exec}}

The new pod reads 2/2 and has a `SYNCED` row.

## Verify the call

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

HTTP 200. The caller's mTLS now ends at `session-broker`'s sidecar. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m15-service-mesh/ANSWER-KEY.md).
