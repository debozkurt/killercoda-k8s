# Step 1 — The owner chain

You write a Deployment. You get Pods. Two controllers sit in between, and seeing the chain is the foundation for everything else in this module.

## See all three levels at once

```bash
kubectl get deploy,rs,pods -n app-services -l app=sip-app
```{{exec}}

You'll see one Deployment (`sip-app`), one ReplicaSet (`sip-app-<hash>`), and two Pods (`sip-app-<hash>-<id>`). The names tell the story: the ReplicaSet is named after the Deployment plus a template hash; each Pod is named after its ReplicaSet. That's the **owner chain** — Deployment owns ReplicaSet owns Pods.

## Confirm ownership directly

The chain isn't just a naming convention; it's recorded in each object's `ownerReferences`.

```bash
kubectl get rs -n app-services -l app=sip-app \
  -o jsonpath='{.items[0].metadata.ownerReferences[0].kind}/{.items[0].metadata.ownerReferences[0].name}'; echo
```{{exec}}

That prints `Deployment/sip-app` — the ReplicaSet knows who owns it. Pods carry the same reference pointing at the ReplicaSet. This is the chain M00 told you to climb when a controller fails to create something: the failure event lands on the *owner*, not the missing child.

## Watch reconciliation happen

A Deployment is a contract — "keep 2 of these running." Test it: delete a Pod and watch the ReplicaSet replace it.

```bash
POD=$(kubectl get pod -n app-services -l app=sip-app -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD -n app-services
kubectl get pods -n app-services -l app=sip-app
```{{exec}}

The Pod you deleted is gone (or `Terminating`), and a new one is already being created. You never told Kubernetes "make a replacement" — the ReplicaSet controller noticed `desired=2, current=1` and acted. That gap-closing loop is **reconciliation**, and it runs forever.

## Verify

```bash
kubectl get deploy sip-app -n app-services
```{{exec}}

`READY 2/2` — the Deployment is satisfied again. The lesson: you manage the Deployment; the controllers manage the Pods. Editing a live Pod is pointless — the ReplicaSet will replace it. Change the Deployment and let it roll.
