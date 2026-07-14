# Step 2 — Config as environment variables

The first consumption mode: inject config keys as environment variables. `envFrom` injects *every* key of a ConfigMap or Secret; `env` with a `valueFrom` injects *one* named key. The cleanest way to see what a container actually got is to read its environment from inside it.

## Read the env out of a running container

`kubectl exec` runs a command inside a running Pod's container — here `printenv` to print environment variables:

```bash
kubectl exec deploy/session-broker -n media -- printenv LOG_LEVEL MAX_SESSIONS
```{{exec}}

```text
info
500
```

Those are the two `app-config` keys, injected by `envFrom`. A Secret consumed as env looks identical from inside the container — plain env vars, no hint they came from a Secret:

```bash
kubectl exec deploy/account-provisioner -n provisioning -- printenv DB_HOST DB_PASSWORD
```{{exec}}

`account-provisioner` gets `DB_HOST` and `DB_PASSWORD` from its `database-creds` Secret via `envFrom`.

## See the wiring in the spec

The injection is declared in the Pod template. Read the whole Deployment YAML — get used to the shape of the object you'd actually edit:

```bash
kubectl get deploy session-broker -n media -o yaml
```{{exec}}

It's a big object; the config wiring is a few lines under the container spec. Find **`envFrom:`** inside `spec.template.spec.containers`:

```text
        envFrom:
        - configMapRef:
            name: app-config
```

That one block is the whole link from object to environment. (`describe pod` surfaces the same thing more briefly as *Environment Variables from:*, but the YAML is the source of truth.)

## The catch: env is frozen

Environment variables are materialized **once**, when the container starts, and never change after. Edit `app-config` now and `printenv` would still show the old value until the Pod restarts — there's no live update path for env. Hold onto that; it's the root of a whole class of "I changed the config and nothing happened" incidents. The other consumption mode behaves differently — that's next.
