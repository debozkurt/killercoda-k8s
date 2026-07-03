# Step 1 — Trace the missing ConfigMap

The build and apply succeeded, so the cluster has objects to inspect. Start with the Pod:

```bash
kubectl get pods -n edge -l app=edge-relay
```{{exec}}

`0/1  CreateContainerConfigError` — the Pod scheduled, but the kubelet can't assemble the container's configuration. `describe` names the reason:

```bash
kubectl describe pod -n edge -l app=edge-relay | grep -A3 -E 'Events:|Warning'
```{{exec}}

```text
Error: configmap "edge-relay-conf" not found
```

The container's `envFrom` wants a ConfigMap called `edge-relay-conf`, and it isn't there. Confirm what *is* there:

```bash
kubectl get configmap -n edge | grep edge-relay
```{{exec}}

There's an `edge-relay-config-<hash>` — but no `edge-relay-conf`. So the generator produced a ConfigMap under one name and the Deployment is asking for another. This is the hash-reference machinery from the baseline, failing.

## Read the render, not just the cluster

The cluster shows the *result*; the render shows *why*. Look at what Kustomize built:

```bash
cd /root/edge-relay
kubectl kustomize overlays/prod | grep -E 'kind: ConfigMap|name: edge-relay|configMapRef'
```{{exec}}

The generated ConfigMap is `edge-relay-config-<hash>`, but the Deployment's `configMapRef.name` is a bare `edge-relay-conf` — **no hash, and it doesn't match the generated object.** In the healthy baseline, that reference was rewritten to the hashed name. Here it wasn't. Why?

## The name-match rule

Kustomize rewrites a reference to a generated ConfigMap only when the reference's name **exactly matches the generator's declared name**. Line the two up:

```bash
grep -A1 configMapRef base/deployment.yaml
grep -A1 configMapGenerator base/kustomization.yaml
```{{exec}}

The Deployment references `edge-relay-conf`; the generator is named `edge-relay-config`. They differ, so Kustomize never treated the `envFrom` as a reference to *its* ConfigMap — it left the bare name in place, and the hash suffix was never applied. The Deployment points at a ConfigMap that was never created. On to the fix.
