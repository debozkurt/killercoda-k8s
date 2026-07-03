# Step 3 — Mutation injects a default

A `mutate` rule rewrites an object on its way in. The platform uses one to stamp an `owner` label on every tenant Pod — a default authors can't forget — so the stored object differs from the YAML that was submitted.

## The label no one wrote

```bash
kubectl get pods -n tenant-apps -L owner
```{{exec}}

`tenant-web`'s Pod carries `owner=platform`. Nothing in the workload's manifest sets that — the mutate rule added it at admission. Read the rule:

```bash
kubectl get clusterpolicy add-owner-label -o yaml | grep -A10 'mutate:'
```{{exec}}

`patchStrategicMerge` adds `metadata.labels.owner: platform`. The `+(owner)` anchor means "add only if absent," so it never overwrites an owner someone set deliberately.

## Confirm it's admission-time, not in the source

```bash
kubectl get deploy tenant-web -n tenant-apps -o jsonpath='{.spec.template.metadata.labels}' ; echo
```{{exec}}

The label is present on the live object's Pod template because the mutation rewrote it during admission of the Deployment. This is the debugging cue for later: when a field on a running Pod doesn't match the YAML on disk, a mutate policy is the first suspect — and mutation only ever happens at admission, never retroactively.
