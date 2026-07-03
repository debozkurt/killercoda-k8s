# Step 2 — Mutate then validate admits a bare Pod

The API server runs **all mutating webhooks first, then all validating webhooks**. That ordering is a contract you can build on: the mutating webhook injects `env=tenant`, and the validating webhook requires `env` — so a Pod submitted with no label is admitted anyway, because the label is present by the time validation runs. `tenant-web` proves it.

## The workload is up, and carries a label its manifest never set

```bash
kubectl get deploy -n tenant-apps
kubectl get pods -n tenant-apps -L env
```{{exec}}

`tenant-web` is `1/1` and its Pod shows `ENV = tenant`. Now read what the Deployment actually asked for:

```bash
kubectl get deploy tenant-web -n tenant-apps -o jsonpath='{.spec.template.metadata.labels}' ; echo
```{{exec}}

The template labels are `app`, `plane`, `tier` — **no `env`.** No one wrote that label. The mutating webhook added it at admission, which is why the *stored* object differs from the manifest on disk.

## See the ordering directly

A server-side dry-run runs the webhooks (they declare `sideEffects: None`) without persisting anything, and returns the object as it *would* be admitted — mutation included:

```bash
kubectl run probe --image=nginx:1.25 -n tenant-apps --dry-run=server \
  -o jsonpath='{.metadata.labels}' ; echo
```{{exec}}

The returned Pod carries `env: tenant` even though you never set it: the mutating webhook injected it, and the validating webhook admitted it because it was there. Mutate supplies what validate requires — the whole reason the ordering is fixed. (Remove the mutation and validation would reject this same Pod; that is break/fix 02.)
