# Step 2 — Pin the tag and verify

The policy is right — `:latest` shouldn't run. Pin the image to an explicit version and the next Pod passes admission.

## Pin the image

Set the container image to a real, pinned tag:

```bash
kubectl set image deployment/call-recorder app=nginx:1.25 -n tenant-apps
```{{exec}}

Or edit it in place — change `image: nginx:latest` to `image: nginx:1.25`:

```bash
kubectl edit deployment call-recorder -n tenant-apps
```

Either way, the Pod template changes, the ReplicaSet rolls a new Pod, and this one names an explicit non-`latest` tag — so `disallow-latest-tag` admits it.

## Verify

```bash
kubectl rollout status deployment/call-recorder -n tenant-apps --timeout=60s
kubectl get pods -n tenant-apps -l app=call-recorder
```{{exec}}

`call-recorder` reaches `1/1` and its Pod is `Running`. The image gate passed because the tag is now explicit — the same policy that rejected `:latest` accepts `nginx:1.25`. In production the durable form of this is stronger still: a digest (`@sha256:…`) or a signature-verified image (`verifyImages`), so what runs is provably fixed. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
