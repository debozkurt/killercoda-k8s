# Step 2 — Logs: what the process said

`kubectl logs` returns a container's **stdout and stderr**, and only those. That is the container logging contract.

## Make a request, then read the log

`session-broker` is an nginx that logs each request to stdout. Send one request from a throwaway Pod:

```bash
kubectl run obs-curl --rm -i --restart=Never --image=curlimages/curl:8.11.1 -n media \
  -- curl -s -o /dev/null -w "%{http_code}\n" session-broker
```{{exec}}

The command prints 200. Now read what nginx logged:

```bash
kubectl logs deploy/session-broker -n media --tail=3
```{{exec}}

The last line is the access log for the request you just made. The kubelet captured nginx's stdout to a file on the node, and `kubectl logs` read it back.

## The flags

```bash
kubectl logs deploy/session-broker -n media --since=5m --timestamps | tail -5
```{{exec}}

- `--tail=N` and `--since=15m` limit the output. `-f` follows live (Ctrl-C stops it).
- `-c <container>` selects one container in a Pod with several. `--all-containers` reads all of them.
- `--previous` reads the last terminated instance of a container. Step 5 uses it.

## The contract

The kubelet captures only stdout and stderr. An app that writes its log to a file inside the container produces an empty `kubectl logs`. The app logs and you see nothing. You fix that in break/fix 01.

Logs also leave with the Pod. When the node removes a Pod, it removes the log files. Next: metrics.
