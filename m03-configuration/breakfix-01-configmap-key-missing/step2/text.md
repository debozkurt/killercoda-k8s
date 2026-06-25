# Step 2 — Fix it and verify

Two sides, one mismatch: the Pod asks for `MAX_CONNECTIONS`; the ConfigMap has `MAX_SESSIONS`. The fix depends on which side is right. The intended key here is `MAX_SESSIONS` (the one that exists and that the baseline used) — so correct the reference.

## Point the reference at the real key

A Deployment is mutable, so edit it in place and it rolls a new Pod:

```bash
kubectl patch deployment session-broker -n media --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/valueFrom/configMapKeyRef/key","value":"MAX_SESSIONS"}]'
```{{exec}}

Or by hand:

```bash
kubectl edit deployment session-broker -n media
# change  key: MAX_CONNECTIONS  to  key: MAX_SESSIONS
```

## Know the other valid fix

If the application genuinely needs a `MAX_CONNECTIONS` setting, the right fix is the opposite side — add the key to the ConfigMap instead:

```bash
kubectl patch configmap app-config -n media -p '{"data":{"MAX_CONNECTIONS":"200"}}'
kubectl rollout restart deployment session-broker -n media   # env is frozen — must restart to pick it up
```

Either resolves the mismatch. A third option — marking the reference `optional: true` — lets the Pod start *without* the value; use it only when the app has a sane fallback, since it trades a loud failure for a silent missing setting.

## Verify

```bash
kubectl get pods -n media -l app=session-broker
```{{exec}}

`session-broker` is back to `Running` `1/1`. The reference now resolves to a key that exists, so the kubelet can build the container's environment.

For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
