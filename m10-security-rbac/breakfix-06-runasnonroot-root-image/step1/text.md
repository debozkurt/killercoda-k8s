# Step 1 — Diagnose the container that never starts

A Pod exists, so admission accepted it. Find the component that refused it next.

## Read the Pod status

```bash
kubectl get deploy,pods -n payments
```{{exec}}

The Pod STATUS reads `CreateContainerConfigError`. The scheduler placed the Pod, and the kubelet refused to create its container.

## Read the reason

```bash
kubectl describe pod -n payments -l app=ledger-sync
```{{exec}}

In `Events:`, find the `Failed` line:

```text
Error: container has runAsNonRoot and image will run as root (pod: "ledger-sync-…", container: app)
```

The kubelet wrote this event, not the API server. Before it starts a container with `runAsNonRoot: true`, the kubelet works out which user the process will run as. With no `runAsUser`, it reads the user from the image.

## Read the security settings

```bash
kubectl get deploy ledger-sync -n payments -o yaml | grep -A4 'securityContext:'
```{{exec}}

The Pod-level block sets `runAsNonRoot: true` and a seccomp profile, with no `runAsUser`. busybox declares no `USER`, so it runs as UID 0. `runAsNonRoot` is a check, not a switch. It does not change the user. It refuses a container whose user is root.

`restricted` requires `runAsNonRoot` and does not require `runAsUser`. So admission accepted a Pod that the kubelet cannot start.
