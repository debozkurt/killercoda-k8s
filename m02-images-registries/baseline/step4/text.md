# Step 4 — A healthy private-registry pull

Public images pull anonymously. Internal ones don't — the registry demands credentials, and an anonymous pull gets `401 Unauthorized`. This step shows the healthy version: an `imagePullSecret` wired correctly.

## The private registry rejects anonymous pulls

There's a `registry:2` running at `localhost:5000` with basic auth. Ask it anonymously, then with credentials:

```bash
curl -s -o /dev/null -w "anon: %{http_code}\n" http://localhost:5000/v2/
curl -s -o /dev/null -w "auth: %{http_code}\n" -u polyphone:reg-pass http://localhost:5000/v2/
```{{exec}}

Anonymous returns `401`; authenticated returns `200`. That `401` is the exact failure `breakfix-03` produces inside the cluster — same cause, surfaced as `ImagePullBackOff`.

## The kubelet authenticates with an imagePullSecret

`media-recorder` pulls successfully because its pod carries an `imagePullSecret` — a Secret of type `dockerconfigjson` holding the registry credentials:

```bash
kubectl describe secret regcred -n media
kubectl get pod -n media -l app=media-recorder -o yaml
```{{exec}}

In the `describe secret` output, the `Type:` line reads `kubernetes.io/dockerconfigjson`. In the pod YAML, the pod's `spec:` carries the reference:

```text
  imagePullSecrets:
  - name: regcred
```

The secret is the right type, and the pod references it by name (`regcred`). Two facts decide most auth incidents: the secret is **namespaced** (a `regcred` in `media` does nothing for a pod in `signaling`), and its registry server must **match the image host exactly** (`localhost:5000`). Two facts decide most auth incidents: the secret is **namespaced** (a `regcred` in `media` does nothing for a pod in `signaling`), and its registry server must **match the image host exactly** (`localhost:5000`).

## Confirm the healthy result

```bash
kubectl get pods -n media -l app=media-recorder
```{{exec}}

`media-recorder` is `Running`, `1/1` — the proprietary image pulled from the private registry with the credentials the `imagePullSecret` supplied. That's the whole healthy path. The break/fix scenarios each sever one link in it.
