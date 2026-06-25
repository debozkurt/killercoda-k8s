# Step 2 — Make the change take, and verify

The ConfigMap is already correct (`debug`). The Pod just needs to restart so its container re-reads the config at start. Nothing about the manifests is wrong to *fix* — you trigger a roll.

## Roll the consumers

`kubectl rollout restart` replaces every Pod in the Deployment with a fresh one, which re-injects env from the current ConfigMap:

```bash
kubectl rollout restart deployment session-broker -n media
```{{exec}}

Wait for the new Pod to be ready:

```bash
kubectl rollout status deployment session-broker -n media
```{{exec}}

## The durable way

`rollout restart` is the right tool for an incident — fast and obvious — but it's an imperative action, invisible to your Git source of truth. The GitOps-native pattern is a **config-hash annotation**: stamp a checksum of the ConfigMap into the Pod template's annotations, so any change to the config changes the template hash and rolls the Deployment automatically. The restart becomes part of the declarative change rather than a thing you remember to run (Kustomize and Helm config generators do this for you — M16–M17). Marking config objects `immutable` and referencing them by a hashed name is the same idea taken further.

## Verify

```bash
kubectl exec deploy/session-broker -n media -- printenv LOG_LEVEL
```{{exec}}

```text
debug
```

The running container now serves `debug`, matching the ConfigMap. The config and the workload agree again.

For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
