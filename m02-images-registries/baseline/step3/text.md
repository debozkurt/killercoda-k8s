# Step 3 — imagePullPolicy and the node cache

Before the kubelet pulls anything, `imagePullPolicy` decides *whether* it should — pull fresh, or reuse what's already cached on the node.

## The three policies

- **`Always`** — check the registry on every pod start; pull if the cached digest differs. Safe for moving tags, costs a round-trip.
- **`IfNotPresent`** — use the node's cached image if any copy exists; only pull when absent. Fast, but a warm cache can serve stale bytes for a mutable tag.
- **`Never`** — never contact a registry. Use the cache or fail with `ErrImageNeverPull`.

## See the default the API applied

Most fleet workloads don't set a policy, so Kubernetes defaults one from the reference. Check `media-recorder`:

```bash
kubectl get pod -n media -l app=media-recorder \
  -o jsonpath='{.items[0].spec.containers[0].imagePullPolicy}{"\n"}'
```{{exec}}

It shows `IfNotPresent` — the default for any tag that isn't `:latest` (and for digests). The rule encodes the lesson: a `:latest` tag defaults to `Always` (re-check the moving target every time); a specific tag or digest defaults to `IfNotPresent` (trust the cache, because pinned content can't be wrong).

## Watch a pull happen once

The kubelet logs whether it pulled or reused the cache in the pod's events:

```bash
kubectl describe pod -n media -l app=media-recorder | sed -n '/Events/,$p'
```{{exec}}

You'll see a `Pulling image "localhost:5000/polyphone/media-recorder:1.4.2"` event followed by `Successfully pulled` — this pod's first pull, since the node hadn't cached it. A second pod on the same node with `IfNotPresent` would skip straight to `Created` with no `Pulling` event, because the image is now cached.

`Never` + an uncached image is the failure in `breakfix-01`: the kubelet refuses to pull and the pod stalls — distinct from every other pull failure because *no pull is even attempted*.
