# Step 3 — Config as mounted files

The second consumption mode: project a ConfigMap or Secret into a directory as files — one file per key, the key as the filename and the value as the contents. Same objects, different shape inside the container.

## List the mounted config

`session-broker` mounts `app-config` at `/etc/app-config`:

```bash
kubectl exec deploy/session-broker -n media -- ls /etc/app-config
```{{exec}}

```text
LOG_LEVEL
MAX_SESSIONS
```

Each key became a file. Read one:

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

## Why the mode matters: updates

The two modes diverge on updates. A **mounted** ConfigMap/Secret tracks its source — edit the object and the kubelet refreshes the files after roughly its sync period (~1 minute), no restart needed. **Env vars never update** (step 2). One exception: a `subPath` mount — used to drop a single file into a directory without hiding the rest — is frozen like env, *not* live-updated.

A **projected volume** is the general form: it combines a ConfigMap, a Secret, downward-API fields, and a ServiceAccount token into one directory. The short-lived ServiceAccount token every Pod carries arrives exactly this way.

## Verify

```bash
kubectl get deploy session-broker -n media -o yaml | grep -A3 volumeMounts
```{{exec}}

You'll see the `app-config` mount at `/etc/app-config`. Same object as the env in step 2, consumed twice — that's the choice the next scenarios turn on.
