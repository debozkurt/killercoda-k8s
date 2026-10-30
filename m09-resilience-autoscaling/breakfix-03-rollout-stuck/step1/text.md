# Step 1 — Diagnose the stuck rollout

The service is up and the rollout is wedged. Read the Deployment's view of the rollout before you read any Pod.

## The rollout has not finished

```bash
kubectl get deployment portal-web -n admin-portal
kubectl rollout status deployment/portal-web -n admin-portal --timeout=10s
```{{exec}}

READY reads 2/2 and AVAILABLE reads 2, but UP-TO-DATE reads 1. Only one Pod runs the new version. The status command waits and then times out with:

```text
Waiting for deployment "portal-web" rollout to finish: 1 out of 2 new replicas have been updated...
```

The timeout is the expected result.

## Two ReplicaSets, one broken

```bash
kubectl get rs -n admin-portal -l app=portal-web
kubectl get pods -n admin-portal -l app=portal-web
```{{exec}}

The old ReplicaSet keeps 2 Pods Running, which is why users are fine. The new ReplicaSet has a Pod in `ImagePullBackOff`. With 2 replicas, `maxUnavailable` rounds down to 0. The Deployment cannot retire an old Pod until the new one is Ready, so it waits.

## Read the Deployment

```bash
kubectl describe deployment portal-web -n admin-portal
```{{exec}}

Read three places. In the Pod template, `Image:` reads nginx:1.25-doesnotexist. In `Conditions:`, `Available` is `True` and `Progressing` is `False` with reason `ProgressDeadlineExceeded`. The `NewReplicaSet:` line names the broken set. Kubernetes reports the stall and takes no action.

```bash
kubectl rollout history deployment/portal-web -n admin-portal
```{{exec}}

Two revisions: a good one and this one. A known-good revision exists to return to. Next: roll back.
