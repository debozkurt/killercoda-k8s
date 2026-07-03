# Step 4 — Generators and the hash contract

Why does the generated ConfigMap carry a hash at all? Because it makes config changes *safe*. A hand-written ConfigMap has a fixed name; editing its data in place updates the object, but running Pods keep their already-loaded values and **nothing tells the Deployment to restart**. A generator ties the ConfigMap's name to its contents, so any change produces a new name — which changes the Deployment's reference — which is a template change — which triggers a rollout.

Watch it happen. Note the current reference, then change one value in the prod overlay:

```bash
kubectl get deploy edge-relay -n edge \
  -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}{"\n"}'
```{{exec}}

Raise the session ceiling from 5000 to 6000 in the prod overlay's generator:

```bash
sed -i 's/MAX_SESSIONS=5000/MAX_SESSIONS=6000/' overlays/prod/kustomization.yaml
kubectl kustomize overlays/prod | grep -E 'name: edge-relay-config|MAX_SESSIONS'
```{{exec}}

The rendered ConfigMap name is **different** now — same object, new contents, new hash. Apply it and watch the Deployment roll:

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

A new ReplicaSet came up because the Pod template's `configMapRef.name` changed. Confirm the new reference and that it carries 6000:

```bash
REF=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
kubectl get configmap "$REF" -n edge -o jsonpath='{.data.MAX_SESSIONS}{"\n"}'
```{{exec}}

## The catch: old generated objects linger

`apply -k` created the *new* ConfigMap but did not delete the old one — apply only touches what the render contains. List them:

```bash
kubectl get configmap -n edge | grep edge-relay-config
```{{exec}}

You'll usually see two. In a real pipeline you either run `kubectl apply -k … --prune` (with a label selector) or let a GitOps controller (Flux, Argo CD) garbage-collect resources that left the desired set — otherwise stale generated ConfigMaps pile up. That's the trade-off the hash buys you: automatic, safe rollouts on config change, at the cost of leftover objects you have to prune.

That's the healthy machine end to end. Now go break it — the three scenarios each fault one mechanism you just watched work.
