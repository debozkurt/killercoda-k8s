# Step 1 — Diagnose the Forbidden

A CrashLoop usually means a broken app. This one is a broken *permission* — the logs say so.

## Confirm it's crashing

```bash
kubectl get pods -n media -l app=endpoint-watcher
```{{exec}}

`CrashLoopBackOff`, restarts climbing. The Pod schedules and starts — not a scheduling or image problem — but its process keeps exiting.

## Read the logs — it's a 403, not a bug

```bash
kubectl logs -n media deploy/endpoint-watcher --tail=8
```{{exec}}

The container calls the API, prints the response, then exits because the call failed:

```text
GET /api/v1/namespaces/media/endpoints -> HTTP 403
{"kind":"Status", ... "message":"endpoints is forbidden: User
\"system:serviceaccount:media:endpoint-watcher\" cannot list resource
\"endpoints\" in API group \"\" in the namespace \"media\"","reason":"Forbidden", ...}
```

Read the message like a sentence: the **identity** is `system:serviceaccount:media:endpoint-watcher` (the SA we intended), the **verb** is `list`, the **resource** is `endpoints`, the **scope** is `in the namespace "media"`. The caller is who we meant — so the *permission* is what's short.

## Reproduce it as a yes/no

```bash
kubectl auth can-i list endpoints -n media \
  --as=system:serviceaccount:media:endpoint-watcher
```{{exec}}

`no`. Now see what the SA *can* do with endpoints:

```bash
kubectl auth can-i --list -n media \
  --as=system:serviceaccount:media:endpoint-watcher | grep -i endpoints
```{{exec}}

It holds `get` and `watch` — but not `list`. Read the Role it's bound to:

```bash
kubectl describe role endpoint-reader -n media
```{{exec}}

`Verbs: [get watch]`. The reader does a `list` (a GET on the endpoints *collection*, which the `list` verb governs) and the Role never granted it. One verb short. On to the fix.
