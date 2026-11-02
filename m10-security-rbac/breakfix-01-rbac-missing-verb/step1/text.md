# Step 1 — Diagnose the Forbidden

A crash loop usually means a broken application. Read the logs before you assume that.

## Confirm the crash loop

```bash
kubectl get pods -n media -l app=endpoint-watcher
```{{exec}}

`CrashLoopBackOff`, with restarts climbing. The Pod was scheduled and its image pulled, so the process starts and then exits.

## Read the logs

```bash
kubectl logs -n media deploy/endpoint-watcher --tail=8
```{{exec}}

The container calls the API, prints the response, and exits on failure. Find the `message` field:

```text
endpoints is forbidden: User "system:serviceaccount:media:endpoint-watcher"
cannot list resource "endpoints" in API group "" in the namespace "media"
```

Read it field by field:

- identity: `endpoint-watcher`, the workload's own ServiceAccount
- verb: `list`
- resource: `endpoints`, in API group "" (the core group)
- scope: the namespace `media`

The identity is the intended one, so the permission is short.

## Reproduce it as a yes or no

```bash
kubectl auth can-i list endpoints -n media --as=system:serviceaccount:media:endpoint-watcher
```{{exec}}

The answer is no. Now list everything this identity holds:

```bash
kubectl auth can-i --list -n media --as=system:serviceaccount:media:endpoint-watcher
```{{exec}}

Find the `endpoints` row. Its verbs column reads [get watch]. Read the Role behind it:

```bash
kubectl describe role endpoint-reader -n media
```{{exec}}

The rule row for `endpoints` lists [get watch]. The reader sends a GET on the endpoints collection, and the API server maps a collection GET to the `list` verb. The Role never grants `list`.
