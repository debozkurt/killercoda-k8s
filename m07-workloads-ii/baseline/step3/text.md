# Step 3 — StatefulSet storage: one claim per ordinal

Each ordinal owns a volume, and the volume follows the ordinal, not the Pod.

## One claim per ordinal

A StatefulSet carries a `volumeClaimTemplate`. The controller creates one claim from it for each ordinal:

```bash
kubectl get pvc -n media
```{{exec}}

`state-media-engine-0` and `state-media-engine-1`. The name pattern is `<template>-<statefulset>-<ordinal>`. Both claims are `Bound`. Read the template that produced them:

```bash
kubectl describe statefulset media-engine -n media
```{{exec}}

Find the `Volume Claims:` block. It names the template `state`, the StorageClass `local-path`, and the access mode `ReadWriteOnce`.

## The claim follows the ordinal

Find which claim `media-engine-0` mounts:

```bash
kubectl describe pod media-engine-0 -n media
```{{exec}}

In the `Volumes:` block, the `state` volume reads `ClaimName: state-media-engine-0`. If the Pod is deleted or rescheduled, the controller mounts this same claim into the new `media-engine-0`.

Deleting or scaling down a StatefulSet does not delete its claims. The LESSON covers `persistentVolumeClaimRetentionPolicy`, which changes that. Next: prove it.
