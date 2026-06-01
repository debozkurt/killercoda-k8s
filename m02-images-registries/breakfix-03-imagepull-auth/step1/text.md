# Step 1 — Diagnose the rejected pull

`ImagePullBackOff` again — but the event message points at a different branch than breakfix-02's `no such host`.

## Read the event

```bash
kubectl get pods -n media -l app=media-recorder
kubectl describe pod -n media -l app=media-recorder | sed -n '/Events/,$p'
```{{exec}}

The `Failed` event reads:

```text
Failed to pull image "localhost:5000/polyphone/media-recorder:1.4.2":
  failed to resolve reference ... unexpected status from HEAD request: 401 Unauthorized
```

`401 Unauthorized` is unambiguous: the kubelet reached the registry, sent a pull request, and the registry rejected it for lack of valid credentials. The host resolved (so it's not breakfix-02), and the registry answered (so it's not unreachable) — the credentials are missing or wrong.

## Confirm the registry really wants auth

You can reproduce the `401` directly against the registry to prove it's an auth gate, not a broken registry:

```bash
curl -s -o /dev/null -w "anon: %{http_code}\n" http://localhost:5000/v2/
curl -s -o /dev/null -w "auth: %{http_code}\n" -u polyphone:reg-pass http://localhost:5000/v2/
```{{exec}}

Anonymous → `401`; with credentials → `200`. The registry is healthy; it simply requires authentication that the pod isn't providing.

## Find the missing credential wiring

The kubelet authenticates a pull using an `imagePullSecret` on the pod (or its ServiceAccount). Check whether `media-recorder` has one — and whether the secret even exists:

```bash
kubectl get pod -n media -l app=media-recorder \
  -o jsonpath='pullSecrets={.items[0].spec.imagePullSecrets}{"\n"}'
kubectl get secret -n media | grep -i regcred || echo "no regcred secret in media"
```{{exec}}

`pullSecrets=` is empty, and there's no `regcred` secret in `media`. The pod is pulling anonymously from a registry that demands auth. The fix is to give the kubelet credentials: create a `docker-registry` secret and attach it. On to the fix.
