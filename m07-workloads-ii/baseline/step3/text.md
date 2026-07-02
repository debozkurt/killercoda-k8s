# Step 3 — StatefulSet storage: sticky per-ordinal PVCs

The third guarantee: each ordinal gets its own volume, and that volume follows the ordinal — not the Pod instance.

## One PVC per ordinal

The StatefulSet declares a `volumeClaimTemplate`, and the controller stamps one PVC per replica:

```bash
kubectl get pvc -n media
```{{exec}}

`state-media-engine-0` and `state-media-engine-1` — the naming is `<template>-<sts>-<ordinal>`. Each is a distinct, `Bound` claim. Confirm the template that produced them:

```bash
kubectl get statefulset media-engine -n media \
  -o jsonpath='{.spec.volumeClaimTemplates[0].metadata.name}{"\n"}'
```{{exec}}

`state`. The controller expands that one template into a per-ordinal PVC and mounts each into its matching Pod.

## The claim tracks the ordinal, not the Pod

See which claim `media-engine-0` actually mounts:

```bash
kubectl get pod media-engine-0 -n media \
  -o jsonpath='{.spec.volumes[?(@.name=="state")].persistentVolumeClaim.claimName}{"\n"}'
```{{exec}}

`state-media-engine-0`. If this Pod is deleted and recreated — or rescheduled to another node — the controller re-attaches *this same* claim to the new `media-engine-0`, so it comes back with its own data, not a blank volume. That's why ordinal identity and storage identity are the same guarantee: `0` always means the same name, the same DNS record, and the same disk.

Scaling down doesn't delete these PVCs by default — the data outlives the Pod (controlled by `persistentVolumeClaimRetentionPolicy`, covered in `LESSON.md`). Next: the other controller, and how it decides which nodes it covers.
