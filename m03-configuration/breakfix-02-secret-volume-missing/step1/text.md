# Step 1 — Diagnose the stuck pod

The Pod never reaches the container, so there are no logs and no container-level error. The state and the events tell you why.

## Read the status

```bash
kubectl get pods -n admin-portal
```{{exec}}

Both `portal-ui` pods read `0/1` `ContainerCreating` and stay there. This is not `CreateContainerConfigError` (the kubelet never got as far as creating the container) and not a crash. `ContainerCreating` that never resolves almost always means the kubelet is stuck setting up a **volume**.

## Find the FailedMount event

```bash
kubectl describe pod -n admin-portal -l app=portal-ui
```{{exec}}

In the `Events:` section, the kubelet is retrying a mount and failing:

```text
Warning  FailedMount  MountVolume.SetUp failed for volume "portal-secrets" :
         secret "portal-secrets" not found
```

That's the diagnosis: the Pod mounts a Secret named `portal-secrets`, and no such Secret exists in this namespace. Volume setup runs *before* the container starts, so the Pod can't progress — it just keeps retrying.

## Confirm both sides

What does the Pod mount, and does the Secret exist? Read the volume off the spec:

```bash
kubectl get deploy portal-ui -n admin-portal -o yaml | grep -A4 'volumes:'
```{{exec}}

```text
      volumes:
      - name: portal-secrets
        secret:
          secretName: portal-secrets
```

Now look for the Secret:

```bash
kubectl get secret -n admin-portal
```{{exec}}

There's no `portal-secrets` row — only the default ServiceAccount token. The Pod requires a Secret that was never created in this namespace. On to the fix.
