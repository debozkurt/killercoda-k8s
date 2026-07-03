# Step 1 — The base

A **base** is a complete, environment-agnostic kustomization: a set of resources plus the transformations that apply to all environments. Overlays build on it; on its own it renders to valid manifests. Start by reading it.

```bash
cd /root/edge-relay
cat base/kustomization.yaml
```{{exec}}

Three things to notice: `resources:` lists the raw manifests (`deployment.yaml`, `service.yaml`); `namespace: edge` is a transformer that stamps that namespace onto every resource; and `configMapGenerator` *creates* a ConfigMap from literals rather than you writing one by hand.

## Render it — don't apply it

`kubectl kustomize <dir>` builds a kustomization and prints the result to stdout. It touches no cluster. This is the single most useful Kustomize command: *see exactly what will be applied* before applying it.

```bash
kubectl kustomize base
```{{exec}}

Read the output top to bottom. Two details matter for everything later in this module:

**1. The generated ConfigMap has a hash suffix.** Its name isn't `edge-relay-config` — it's `edge-relay-config-` followed by a short hash:

```bash
kubectl kustomize base | grep 'name: edge-relay-config'
```{{exec}}

Kustomize appends a hash of the ConfigMap's *contents* to its name. Change a value, and the name changes.

**2. The Deployment's reference was rewritten to match.** The base Deployment asks for `envFrom: configMapRef: name: edge-relay-config` (the plain name). Look at what the render produced:

```bash
kubectl kustomize base | grep -A1 configMapRef
```{{exec}}

The reference now points at the *hashed* name. Kustomize rewrote it automatically — because the reference's name matched the generator's declared name. Hold onto that: the rewrite is a name match, and it is the thing that breaks in `breakfix-02`.

## Why the base alone isn't enough

The base declares one replica, no environment label, and the same config everywhere. That's deliberate — a base captures what's *common*. Everything that differs per environment (replica count, image tag, config values, placement) lives in the overlays. That's step 2.
