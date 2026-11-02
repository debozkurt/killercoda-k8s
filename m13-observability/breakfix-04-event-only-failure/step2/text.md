# Step 2 — Fix it and verify

The Deployment mounts a ConfigMap that does not exist. Point it at the one that does.

## Correct the volume

```bash
kubectl patch deployment rate-loader -n call-routing --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/volumes/0/configMap/name","value":"rate-table"}]'
```{{exec}}

This edits the Pod template, so the Deployment starts a new Pod that mounts a real ConfigMap. Creating a ConfigMap named rate-table-v2 also works. The kubelet retries the mount on its own, and the stuck Pod starts without a restart.

## Roll out and verify

```bash
kubectl rollout status deployment rate-loader -n call-routing --timeout=90s
kubectl get pods -n call-routing -l app=rate-loader
kubectl events -n call-routing --types=Warning
```{{exec}}

The Pod reads Running 1/1. The old Warning stays in the list until its one-hour TTL ends. The event lists the past, and the Pod shows the present. Check the log now:

```bash
kubectl logs -n call-routing deploy/rate-loader --tail=3
```{{exec}}

nginx prints its startup lines, so a log exists once the container runs. Read `finish.md`, then check `ANSWER-KEY.md`.
