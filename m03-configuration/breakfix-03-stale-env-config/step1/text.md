# Step 1 — Diagnose the stale value

Nothing is in a failed state, so there's no event to read. The diagnosis is a comparison: what the ConfigMap says vs what the container actually has.

## Read the ConfigMap

```bash
kubectl describe configmap app-config -n media
```{{exec}}

Read the `Data` section — `LOG_LEVEL` now reads `debug`:

```text
Data
====
LOG_LEVEL:
----
debug
MAX_SESSIONS:
----
500
```

The source of truth says `debug`. The edit landed.

## Read what the container actually got

```bash
kubectl exec deploy/session-broker -n media -- printenv LOG_LEVEL
```{{exec}}

```text
info
```

There's the disagreement: the ConfigMap holds `debug`, the running container still serves `info`. The Pod is `Running` and `Ready` — confirm it's healthy, it's just stale:

```bash
kubectl get pods -n media -l app=session-broker
```{{exec}}

`1/1` `Running`, and its `AGE` predates the config edit — it has not restarted.

## Why the edit didn't reach it

`session-broker` consumes `app-config` via `envFrom`, as environment variables. **Env vars are materialized once, at container start, and never change after.** Editing the ConfigMap updated the object in etcd, but nothing re-injects env into a running container, and a config edit doesn't restart anything — there's no controller watching ConfigMaps to roll your Deployments. So the Pod keeps the `info` it was born with.

(Had this value been consumed as a *mounted file* instead, the kubelet would have refreshed it within about a minute — `subPath` mounts excepted. Env is the consumption mode with no live-update path at all.) The fix is to make the consumers restart so they re-read the config — next.
