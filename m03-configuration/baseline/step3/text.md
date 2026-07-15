# Step 3 — Config as mounted files

The second consumption mode: project a ConfigMap or Secret into a directory as files — one file per key, the key as the filename and the value as the contents. Same objects as step 2, but this mode has a *shape* env vars don't: a directory. So look at how it's wired first, then read what actually landed.

## See how it's wired

`describe` spells the mounts out. `session-broker` has two, and they read differently:

```bash
kubectl describe deploy session-broker -n media
```{{exec}}

In the container's **`Mounts:`** section:

```text
Mounts:
  /etc/app-config from app-config (ro)
  /etc/nginx/broker.conf from broker-tuning (ro,path="broker.conf")
```

`app-config` mounts a whole volume at `/etc/app-config`. `broker-tuning` carries a `path="broker.conf"` — and that `path=` is exactly how `describe` renders a `subPath`: no `path=`, the whole directory is mounted; `path=`, a single file is projected in. Two different shapes from the same kind of object.

## Read the actual values

Now exec in and read what the container got. Each key of `app-config` became a file:

```bash
kubectl exec deploy/session-broker -n media -- ls /etc/app-config
```{{exec}}

```text
LOG_LEVEL
MAX_SESSIONS
```

Read one:

```bash
kubectl exec deploy/session-broker -n media -- cat /etc/app-config/LOG_LEVEL
```{{exec}}

`info` — the same value step 2 saw as an env var, now delivered as a file. A Secret mounts the same way; `portal-ui` projects `portal-secrets` at `/etc/portal`:

```bash
kubectl exec deploy/portal-ui -n admin-portal -- ls /etc/portal
```{{exec}}

```text
ADMIN_API_KEY
SESSION_SECRET
```

Mounting confidential data as files (instead of env) keeps it off the process environment, where a crash dump or a child process could leak it.

The `subPath` mount `describe` flagged lands one file *without* hiding what the image already put in the directory. `session-broker`'s `broker.conf` sits beside nginx's own files:

```bash
kubectl exec deploy/session-broker -n media -- ls /etc/nginx
```{{exec}}

```text
broker.conf  conf.d  fastcgi_params  mime.types  modules  nginx.conf  scgi_params  uwsgi_params
```

`broker.conf` is ours, from the `broker-tuning` ConfigMap; everything else is the image's own. A *plain* volume mount at `/etc/nginx` would have shadowed all of it — the container would see only `broker.conf`. `subPath` drops in the one file and leaves the rest intact:

```bash
kubectl exec deploy/session-broker -n media -- cat /etc/nginx/broker.conf
```{{exec}}

## Why the mode matters: updates

The two modes diverge on updates. A **mounted** ConfigMap/Secret tracks its source — edit the object and the kubelet refreshes the files after roughly its sync period (~1 minute), no restart needed. **Env vars never update** (step 2).

The exception is `subPath`. Because it's a bind mount to a fixed file, it's **frozen** — it does *not* pick up ConfigMap edits the way the whole-directory mount above does. It refreshes only when the Pod is recreated, which is why `subPath` turns up in "I changed the config and nothing happened" incidents.

A **projected volume** is the general form: it combines a ConfigMap, a Secret, downward-API fields, and a ServiceAccount token into one directory. The short-lived ServiceAccount token every Pod carries arrives exactly this way.

## Verify

```bash
kubectl get deploy session-broker -n media -o yaml
```{{exec}}

Two blocks describe the file mount. Under the container spec, **`volumeMounts:`** puts `app-config` at `/etc/app-config`; the **`volumes:`** block lower in the Pod template resolves that name back to the ConfigMap:

```text
        volumeMounts:
        - mountPath: /etc/app-config
          name: app-config
          readOnly: true
...
      volumes:
      - configMap:
          name: app-config
        name: app-config
```

Same object as the env in step 2, consumed twice — that's the choice the next scenarios turn on.
