# Step 4 — Releases and history

Every `install`, `upgrade`, and `rollback` bumps the release's **revision** by one and keeps the old revision around. That history is what makes rollback possible.

## Walk the history

```bash
helm history voicemail -n app-services
```{{exec}}

Two rows: revision 1 (`Install complete`, now `superseded`) and revision 2 (`Upgrade complete`, `deployed`). The `deployed` row is what's live right now.

```bash
helm status voicemail -n app-services
```{{exec}}

`STATUS: deployed`, `REVISION: 2`. `helm status` is the current-state view; `helm history` is the timeline.

## Roll back

Revert to revision 1 (which ran 2 replicas):

```bash
helm rollback voicemail 1 -n app-services
```{{exec}}

A rollback is not a delete — it's a *forward* action that re-applies an old revision's manifests as a **new** revision:

```bash
helm history voicemail -n app-services
```{{exec}}

You now have revision 3 (`Rollback to 1`, `deployed`). The replica count is back to 2:

```bash
kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}{"\n"}'
```{{exec}}

## Where Helm keeps this

Release state lives in the cluster, as a Secret per revision in the release's namespace:

```bash
kubectl get secret -n app-services -l owner=helm
```{{exec}}

You'll see `sh.helm.release.v1.voicemail.v1`, `.v2`, `.v3` — one per revision. This is why `helm` on any machine with cluster access sees the same history: the source of truth is the cluster, not your laptop.

## Verify

```bash
helm history voicemail -n app-services | tail -3
kubectl get deployment voicemail -n app-services -o jsonpath='{.spec.replicas}{"\n"}'
```{{exec}}

Latest revision `deployed`, Deployment at 2 replicas. You've seen the whole model: chart → values → render → release → history. See `finish.md`.
