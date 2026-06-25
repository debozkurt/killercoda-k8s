# Step 2 — Fix it and verify

The Pod requires a Secret that doesn't exist. The fix is to make it exist — and you don't even need to restart the Pod, because the kubelet is already retrying the mount on a loop. Create the Secret and the next retry succeeds.

## Create the missing Secret

The mount expects two keys (`SESSION_SECRET`, `ADMIN_API_KEY`) — the baseline's `portal-secrets`. Create it in `admin-portal`:

```bash
kubectl create secret generic portal-secrets \
  --from-literal=SESSION_SECRET=s3ssion-signing-key \
  --from-literal=ADMIN_API_KEY=adm-9f2a1c7e \
  -n admin-portal
```{{exec}}

`kubectl create secret generic` builds an Opaque Secret; `--from-literal` base64-encodes each value for you (no hand-encoding).

## Watch it self-heal

No `kubectl delete pod`, no rollout — the kubelet retries the failed mount every sync. Give it a few seconds and watch the pods recover:

```bash
kubectl get pods -n admin-portal -w
```{{exec}}

Press `Ctrl-C` once both pods reach `1/1` `Running`. (If you're impatient, `kubectl rollout restart deployment portal-ui -n admin-portal` forces it immediately — but it isn't required.)

## Note the real-world cause

A Secret that "doesn't exist" is usually a Secret that exists *somewhere else*: applied to the wrong namespace, named differently than the Pod expects, or dropped from a manifest set during a refactor. Secrets are namespaced — one in `media` does nothing for a Pod in `admin-portal`. In production the fix is the same shape, but the durable version restores it from your secret source of truth (a secret manager or sealed-secret in Git), not a hand-run `kubectl create`.

## Verify

```bash
kubectl get pods -n admin-portal -l app=portal-ui
```{{exec}}

Both `portal-ui` pods are `Running` `1/1`. The mount the kubelet was blocked on now resolves.

For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
