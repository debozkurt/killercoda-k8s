# Step 1 — Rolling updates and rollback

Every Deployment already knows how to replace its Pods without dropping the service. When you change the Pod template (a new image, a new env var), the Deployment doesn't delete everything and start over — it rolls the change out a few Pods at a time, governed by a **strategy**.

## Read the update strategy

```bash
kubectl get deployment route-engine -n call-routing \
  -o jsonpath='{.spec.strategy}'; echo
```{{exec}}

`type: RollingUpdate`, with `maxSurge: 25%` and `maxUnavailable: 25%`. During an update the Deployment may run up to 25% *extra* Pods (surge) and let up to 25% go *unavailable* — so it always keeps most of the service serving while it swaps Pods. A rollout is really two ReplicaSets in a handoff: the old one scaling down as the new one scales up.

## The revision history

Each rollout is a numbered **revision**, and Kubernetes keeps the recent ones so you can rewind:

```bash
kubectl rollout history deployment/route-engine -n call-routing
```{{exec}}

## Do a healthy rollout

`rollout restart` re-rolls the Deployment with the same template (a common way to cycle Pods, e.g. to pick up a rotated Secret). Watch it proceed and finish:

```bash
kubectl rollout restart deployment/route-engine -n call-routing
kubectl rollout status deployment/route-engine -n call-routing
```{{exec}}

`rollout status` blocks until the new Pods are Ready, then prints `successfully rolled out`. That command is the backbone of every deploy pipeline — it's how automation knows a release actually landed. Now look at the two ReplicaSets it created:

```bash
kubectl get rs -n call-routing -l app=route-engine
```{{exec}}

One ReplicaSet at the desired replica count (the current version), older ones scaled to `0` (kept for rollback). That's the mechanism: the Deployment owns ReplicaSets; a rollout is scaling one down while another scales up.

## Rewind

If a release misbehaves, one command puts the previous revision back:

```bash
kubectl rollout undo deployment/route-engine -n call-routing
kubectl rollout status deployment/route-engine -n call-routing
```{{exec}}

`rollout undo` re-applies the prior revision's template and rolls forward to it — the same careful, few-at-a-time swap, just aimed backward. When a rollout gets *stuck* (breakfix-03), this is the fastest way out. Next: scaling the replica count automatically instead of by hand.
