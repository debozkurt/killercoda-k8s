# Step 1 — Diagnose the config error

No logs, because the container never ran. The status and the events carry the whole story.

## Read the status

```bash
kubectl get pods -n media
```{{exec}}

`session-broker` is not `Running` — its status is **`CreateContainerConfigError`**. That word is specific: the kubelet scheduled the Pod and tried to *create the container*, but couldn't build its configuration. Not a crash, not a pull failure — a config-wiring failure caught at container-creation time.

## Let the event name the missing piece

```bash
kubectl describe pod -n media -l app=session-broker
```{{exec}}

Scroll to the `Events:` section at the bottom. The message is exact:

```text
Error: couldn't find key MAX_CONNECTIONS in ConfigMap media/app-config
```

The kubelet is telling you precisely what's wrong: an `env` reference asked for a key named `MAX_CONNECTIONS` in the `app-config` ConfigMap, and that key isn't there.

## Confirm both sides of the reference

Read the env reference in the Deployment, then the ConfigMap's actual keys. Start with the Deployment YAML:

```bash
kubectl get deploy session-broker -n media -o yaml
```{{exec}}

Under the container spec, the **`env:`** block declares the reference that's failing:

```text
        env:
        - name: MAX_SESSIONS
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: MAX_CONNECTIONS
```

Now the other side — what keys does `app-config` actually have? `describe` lists the `Data` section key by key:

```bash
kubectl describe configmap app-config -n media
```{{exec}}

```text
Data
====
LOG_LEVEL:
----
info
MAX_SESSIONS:
----
500
```

There it is: the ConfigMap has `LOG_LEVEL` and `MAX_SESSIONS`, but the Pod asks for `MAX_CONNECTIONS`. A required `configMapKeyRef` to a key that doesn't exist fails the container, every time. On to the fix.
