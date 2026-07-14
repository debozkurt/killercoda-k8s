# Step 1 — Diagnose the wrong value

Nothing is in a failed state, so the status tells you nothing. The whole diagnosis is reading the value the container actually got and noticing it's wrong.

## Confirm the Pod is healthy

```bash
kubectl get pods -n provisioning
```{{exec}}

`account-provisioner` is `Running` `1/1`. No crashes, no restarts. Kubernetes considers this workload perfectly fine — the problem is in the *value*, not the state.

## Read the injected credential

```bash
kubectl exec deploy/account-provisioner -n provisioning -- printenv DB_PASSWORD
```{{exec}}

```text
Y2hhbmdlbWU=
```

Stop and look at that. A password the application would use to log in shouldn't look like `Y2hhbmdlbWU=` — that's the shape of **base64**, not a plaintext password. The container received an encoded string where it expected a real value.

## Decode it to confirm

```bash
echo 'Y2hhbmdlbWU=' | base64 -d; echo
```{{exec}}

```text
changeme
```

So the *intended* password is `changeme` — but the container is being handed `Y2hhbmdlbWU=`, the base64 *of* `changeme`. The value was encoded one time too many. Look at the Secret to see where — `describe` hides Secret values, so read the YAML:

```bash
kubectl get secret database-creds -n provisioning -o yaml
```{{exec}}

A Secret stores its values base64-encoded under `data:`. Find `DB_PASSWORD`:

```text
data:
  DB_HOST: cG9zdGdyZXMucG9seXBob25lLmV4YW1wbGU=
  DB_PASSWORD: WTJoaGJtZGxiV1U9
```

That `data` is *already* base64 — the kubelet decodes it once before injecting. Decode `WTJoaGJtZGxiV1U9` once and you get `Y2hhbmdlbWU=` (still base64); decode twice and you get `changeme`. The value was base64-encoded twice, so one decode leaves it still encoded. Classic hand-base64 mistake: someone encoded a value that was already encoded. On to the fix.
