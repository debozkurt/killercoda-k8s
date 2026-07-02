# Step 1 — Diagnose the stuck rollout

The service is up but the rollout is wedged. Read the Deployment's own view of the rollout before looking at Pods.

## The rollout hasn't finished

```bash
kubectl get deployment portal-web -n admin-portal
```{{exec}}

`READY 2/2`, `AVAILABLE 2` — but `UP-TO-DATE 1`. Two Pods are ready, yet only one is the *new* version. The old version is still carrying the service; the new one hasn't landed. Ask `rollout status` (with a short timeout so it returns instead of hanging):

```bash
kubectl rollout status deployment/portal-web -n admin-portal --timeout=10s
```{{exec}}

```text
Waiting for deployment "portal-web" rollout to finish: 1 out of 2 new replicas have been updated...
```

It's stuck partway — the new ReplicaSet came up but never became fully ready.

## Two ReplicaSets, one of them broken

```bash
kubectl get rs -n admin-portal -l app=portal-web
kubectl get pods -n admin-portal -l app=portal-web
```{{exec}}

The old ReplicaSet still has its Pods `Running` (that's why users are fine). The new ReplicaSet has a Pod stuck in **`ImagePullBackOff`**. The rolling update surged up one new Pod, it failed to start, and — because the default `maxUnavailable` rounds down to `0` for 2 replicas — the Deployment refuses to retire an old Pod until the new one is Ready. So it waits.

## Why it's stuck, in the Deployment's conditions

```bash
kubectl describe deployment portal-web -n admin-portal | grep -A8 Conditions
```{{exec}}

`Available True` (old version serving) but `Progressing False` with reason **`ProgressDeadlineExceeded`** — the rollout blew past its deadline without becoming healthy. That's Kubernetes flagging "this release is not going to make it," but note it does **not** automatically roll back. Now the root cause — the image:

```bash
kubectl get deployment portal-web -n admin-portal \
  -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
kubectl rollout history deployment/portal-web -n admin-portal
```{{exec}}

The current image is `nginx:1.25-doesnotexist` — a tag that isn't in the registry, so every pull fails. The history shows two revisions: a good `nginx:1.25` (revision 1) and this bad one (revision 2). A good revision to return to exists. On to the fix.
