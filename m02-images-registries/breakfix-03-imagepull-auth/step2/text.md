# Step 2 — Fix it and verify

The kubelet needs registry credentials. Create a `docker-registry` secret in the pod's namespace, then attach it to the workload.

## Create the pull secret

The registry's credentials are `polyphone` / `reg-pass` (in production you'd pull these from your secret manager). The secret must live in the **same namespace** as the pod and name the **same registry host** as the image (`localhost:5000`):

```bash
kubectl create secret docker-registry regcred \
  --docker-server=localhost:5000 \
  --docker-username=polyphone --docker-password=reg-pass \
  -n media
```{{exec}}

This creates a Secret of type `kubernetes.io/dockerconfigjson`. The two fields that decide whether it works are the **namespace** (`media`) and **`--docker-server`** (must match the image's registry host exactly).

## Attach it to the workload

Creating the secret isn't enough — the pod has to reference it. Patch the Deployment's `imagePullSecrets`:

```bash
kubectl patch deployment media-recorder -n media \
  -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}'
```{{exec}}

The Deployment rolls a new pod; this time the kubelet sends the credentials with its pull, the registry returns `200`, and the image comes down.

(Attaching the secret to the `media` ServiceAccount instead would make *every* pod in the namespace inherit it — handy when many workloads share one registry, but more credentials handed out than this single workload needs.)

## Verify

```bash
kubectl get pods -n media -l app=media-recorder
kubectl get pod -n media -l app=media-recorder -o yaml
```{{exec}}

`media-recorder` is `Running` `1/1`, and the pod's `spec:` now carries `imagePullSecrets:` with `- name: regcred`. The pull authenticated. The pull authenticated.

For self-grading, the credential-rotation production angle, and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
