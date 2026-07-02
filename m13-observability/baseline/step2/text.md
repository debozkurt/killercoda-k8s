# Step 2 — Logs: what the process said

`kubectl logs` returns a container's **stdout and stderr** — and *only* those. That's the whole container logging contract.

## Make one request, then read the log

`session-broker` is an nginx that logs to stdout, but only when something hits it. Generate one request, then read it:

```bash
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n media \
  -- curl -s -o /dev/null -w "%{http_code}\n" session-broker
```{{exec}}

`200`. Now read what nginx logged:

```bash
kubectl logs deploy/session-broker -n media --tail=3
```{{exec}}

An access line for the `GET /` you just made. The kubelet captured nginx's stdout to a file on the node; `kubectl logs` streamed it back.

## The flags that matter

```bash
kubectl logs deploy/session-broker -n media --since=5m --timestamps | tail -5
```{{exec}}

- `--tail=N` / `--since=15m` scope the firehose to a count or a window.
- `-f` follows live (Ctrl-C to stop).
- `-c <container>` picks a container in a multi-container Pod; `--all-containers` reads them all. A `1/2` Pod means one of two containers is down — read *that* one (you'll do this in break/fix 02).
- `--previous` (`-p`) reads the **prior, terminated** instance of a container. Nothing here has crashed, so:

```bash
kubectl logs deploy/session-broker -n media --previous 2>&1 | head -2
```{{exec}}

"previous terminated container not found" — there's no dead instance. When a container *has* restarted, `kubectl logs` shows the fresh (often clean, misleading) start and `--previous` shows why the last one died. It's the single most important logs flag at 3am.

## The contract, and why it matters

The kubelet only captures **stdout/stderr**. An app that writes its logs to a file *inside* the container produces an empty `kubectl logs` — the app is logging, you just can't see it (break/fix 01). And these files die with the Pod: delete it and the logs are gone. That impermanence is why a real platform ships logs off the node to a durable store. Next: metrics.
