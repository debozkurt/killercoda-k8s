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

`session-broker` is `Running` `1/1`. It reads `app-config` two ways at once — as environment variables and as mounted files — which the next two steps pull apart. The object and its consumers are separate resources; the wiring between them is what the rest of this module is about.
