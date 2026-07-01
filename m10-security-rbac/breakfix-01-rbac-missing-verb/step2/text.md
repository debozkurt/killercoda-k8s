# Step 2 — Fix it and verify

The Role grants `get` and `watch` on endpoints but not `list`. Add the missing verb and the same identity is authorized.

## Add `list` to the Role

```bash
kubectl patch role endpoint-reader -n media --type=json \
  -p '[{"op":"replace","path":"/rules/0/verbs","value":["get","list","watch"]}]'
```{{exec}}

Or by hand:

```bash
kubectl edit role endpoint-reader -n media
# under rules.verbs: add "list"  ->  ["get", "list", "watch"]
```

RBAC changes take effect immediately — nothing needs to restart for the *authorization* to flip.

## Verify the decision

```bash
kubectl auth can-i list endpoints -n media \
  --as=system:serviceaccount:media:endpoint-watcher
```{{exec}}

`yes`. The permission is fixed. The Pod is still `CrashLoopBackOff` from its earlier failures, and it backs off exponentially — nudge it rather than wait:

```bash
kubectl rollout restart deployment endpoint-watcher -n media
kubectl rollout status deployment endpoint-watcher -n media --timeout=60s
```{{exec}}

## Confirm the reader is healthy

```bash
kubectl get pods -n media -l app=endpoint-watcher
kubectl logs -n media deploy/endpoint-watcher --tail=4
```{{exec}}

`Running`, no new restarts, and the logs now show `HTTP 200` with the endpoints list. The app never changed — the Role did. For self-grading and the full `Forbidden` differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
