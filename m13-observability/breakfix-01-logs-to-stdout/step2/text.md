# Step 2 — Fix it and verify

The app writes to `/var/log/app/session.log` instead of stdout. Get that output onto stdout — two ways.

## Option A (preferred when you own the app): log to stdout

The real fix is to make the app write to stdout in the first place. Edit the container command and drop the file redirect:

```bash
kubectl edit deployment session-logger -n app-services
# in spec.template.spec.containers[0].args, change the echo line from
#   ... >> /var/log/app/session.log
# to just
#   echo "$(date -u +%FT%TZ) session sess-$i established ..."   # no redirect → stdout
```

Now the kubelet captures every session line. This is the twelve-factor default: apps log to stdout, the platform's node collector ships it.

## Option B (when you can't change the app): a streaming sidecar

When the app is a vendored binary you can't reconfigure, add a second container that shares the log volume and tails the file to *its* stdout — the pattern from the lesson. One command:

```bash
kubectl patch deployment session-logger -n app-services --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/-","value":{
    "name":"log-stream","image":"busybox:1.36",
    "command":["/bin/sh","-c","touch /var/log/app/session.log; exec tail -f /var/log/app/session.log"],
    "volumeMounts":[{"name":"logs","mountPath":"/var/log/app"}]
  }}]'
```{{exec}}

The `log-stream` container mounts the same `logs` volume the app writes to, so `tail -f` streams the file's contents to stdout — where the log pipeline can finally see it.

## Roll and verify

```bash
kubectl rollout status deployment session-logger -n app-services --timeout=60s
```{{exec}}

Read the logs again — now with `--all-containers`, since the session lines come from the sidecar (or from `app` itself, if you took Option A):

```bash
kubectl logs -n app-services deploy/session-logger --all-containers=true --tail=6
```{{exec}}

The `session sess-N established …` lines are now visible to `kubectl logs`. The app never changed what it *does* — you changed where its output goes, so the platform can see it. See `finish.md`, and check `ANSWER-KEY.md`.
