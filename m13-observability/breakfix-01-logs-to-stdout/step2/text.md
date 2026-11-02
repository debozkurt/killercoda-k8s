# Step 2 — Fix it and verify

Get the app's output onto stdout. Choose one of two ways.

## Option A: log to stdout (the default choice)

You own the app, so change where it writes. Edit the container's script and remove the file redirect:

```bash
kubectl edit deployment session-logger -n app-services
```{{exec}}

In `spec.template.spec.containers[0].args`, find the line that ends with `>> /var/log/app/session.log`. Delete only that redirect, so `echo` prints to stdout. Save and exit.

## Option B: a streaming sidecar (when you cannot change the app)

A **sidecar** is a second container in the same Pod. This one shares the log volume and prints the file to its own stdout:

```bash
kubectl patch deployment session-logger -n app-services --type=json -p='[
  {"op":"add","path":"/spec/template/spec/containers/-","value":{
    "name":"log-stream","image":"busybox:1.36",
    "command":["/bin/sh","-c","touch /var/log/app/session.log; exec tail -F /var/log/app/session.log"],
    "volumeMounts":[{"name":"logs","mountPath":"/var/log/app"}]
  }}]'
```{{exec}}

## Roll out and verify

Either change edits the Pod template, so the Deployment starts a new Pod:

```bash
kubectl rollout status deployment session-logger -n app-services --timeout=60s
kubectl logs -n app-services deploy/session-logger --all-containers=true --tail=6
```{{exec}}

`--all-containers` reads every container, because with Option B the lines come from log-stream. The `session sess-N established` lines now appear. The app did the same work as before. You changed where its output goes. Read `finish.md`, then check `ANSWER-KEY.md`.
