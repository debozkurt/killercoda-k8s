# Step 2 — Fix it and verify

The Secret holds a double-encoded password. Fix it by recreating the Secret with the value encoded exactly once — and then remember the lesson from break/fix 03: env is frozen, so the running Pod won't see the new value until it restarts.

## Recreate the Secret correctly

The simplest way to get the encoding right is to *not do it yourself*. `kubectl create secret --from-literal` takes plaintext and base64-encodes it exactly once:

```bash
kubectl create secret generic database-creds \
  --from-literal=DB_HOST=postgres.polyphone.example \
  --from-literal=DB_PASSWORD=changeme \
  -n provisioning --dry-run=client -o yaml | kubectl apply -f -
```{{exec}}

(Authoring YAML by hand? Put the plaintext in `stringData` instead of `data` and let the API server encode it — same protection against double-encoding.)

## Roll the consumer — the Secret fix alone isn't enough

The Secret is correct now, but `account-provisioner` already baked the old value into its environment at start. Editing the Secret doesn't touch a running container — exactly the propagation gap from the last scenario. Restart it:

```bash
kubectl rollout restart deployment account-provisioner -n provisioning
kubectl rollout status deployment account-provisioner -n provisioning
```{{exec}}

## Verify

```bash
kubectl exec deploy/account-provisioner -n provisioning -- printenv DB_PASSWORD
```{{exec}}

```text
changeme
```

The container now receives the plaintext password. The kubelet decoded the (correctly, single-) encoded `data` value once, and the result is the real credential — not another layer of base64.

For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
