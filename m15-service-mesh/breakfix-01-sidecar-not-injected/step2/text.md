# Step 2 — Fix it and verify

`session-broker` needs a sidecar. The namespace already enables injection; the workload opted out. Reverse the opt-out and let the Deployment roll new pods — they'll be admitted through the injector.

## Re-enroll the workload

Set the injection annotation back to `"true"` on the Deployment's pod template. Changing the template triggers a rollout, and the replacement pod is created with a sidecar:

```bash
kubectl patch deployment session-broker -n media \
  -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject":"true"}}}}}'
kubectl rollout status deployment session-broker -n media
```{{exec}}

(Removing the annotation entirely — `kubectl edit deployment session-broker -n media` and delete the line — works too, since the namespace default is "inject." Setting it to `"true"` is explicit.)

## Confirm it's in the mesh now

```bash
kubectl get pods -n media -l app=session-broker
istioctl proxy-status | grep session-broker
```{{exec}}

The new pod is `2/2`, and it now shows up in `proxy-status` with `SYNCED` config. It has a sidecar to terminate the callers' mTLS.

## Verify the calls succeed

```bash
kubectl exec -n media deploy/mesh-client -c curl -- \
  curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 5 http://session-broker.media/
```{{exec}}

`HTTP 200`. The caller's mTLS now terminates on `session-broker`'s sidecar, the request reaches the app, and you fixed it without touching the PeerAuthentication or DestinationRule — the mesh's mTLS is intact for everyone. For self-grading and the full path, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
