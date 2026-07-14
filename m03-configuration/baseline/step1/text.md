# Step 1 — ConfigMaps and Secrets on the fleet

Configuration lives in two namespaced objects: a **ConfigMap** (key/value pairs for non-confidential settings) and a **Secret** (the same shape, for confidential data). Both are separate from the workloads that consume them. Start by seeing what's on the fleet.

## List the config objects

```bash
kubectl get configmaps -A | grep -v 'kube-\|kube-root'
```{{exec}}

```bash
kubectl get secrets -A | grep -v 'kube-\|default-token\|sh.helm'
```{{exec}}

Three carry the fleet's app config: `app-config` (a ConfigMap in `media`), `database-creds` (a Secret in `provisioning`), and `portal-secrets` (a Secret in `admin-portal`). The rest are platform plumbing — every namespace gets a `kube-root-ca.crt` ConfigMap and a ServiceAccount token, which is why you filter them out.

## Look inside the ConfigMap

`describe` shows a ConfigMap's keys and values directly:

```bash
kubectl describe configmap app-config -n media
```{{exec}}

Read the `Data` section — two keys:

```text
LOG_LEVEL:
----
info
MAX_SESSIONS:
----
500
```

That's the whole object: plain key/value, no workload attached. A ConfigMap doesn't *do* anything until a Pod references it.

## Find the consumer

`app-config` is consumed by `session-broker`. Confirm the workload is healthy:

```bash
kubectl get pods -n media -l app=session-broker
```{{exec}}

`session-broker` is `Running` `1/1`.

## See how it's wired

`describe` on the Pod shows the config wiring in plain sight — no YAML spelunking:

```bash
kubectl describe pod -n media -l app=session-broker
```{{exec}}

Two places name `app-config`. Under the container, **`Environment Variables from:`** lists `app-config  ConfigMap` — every key injected as an env var (`envFrom`). Lower down, **`Mounts:`** shows the same object at `/etc/app-config`, and the **`Volumes:`** block resolves that mount back to `ConfigMap  app-config`. One object, consumed two ways at once — env vars *and* mounted files. The next two steps pull those apart. The object and its consumers stay separate resources; the wiring between them is what the rest of this module is about.
