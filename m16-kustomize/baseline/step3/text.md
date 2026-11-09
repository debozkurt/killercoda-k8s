# Step 3 — Compare with the live cluster

The setup applied the prod overlay. `kubectl diff -k` builds the overlay, sends it to the API server as a dry run, and prints what would change in the live objects:

```bash
kubectl diff -k overlays/prod; echo "exit=$?"
```{{exec}}

No diff output, and exit=0: the live objects match the render. Exit 1 means a difference exists. Because the API server runs a dry run, an object that it would reject fails here with the same error that `apply` gives.

`kubectl apply -k` runs the same build and applies the result:

```bash
kubectl apply -k overlays/prod
```{{exec}}

Each object reads `unchanged`.

## What landed

The cluster holds rendered objects. Nothing in it knows that Kustomize exists.

```bash
kubectl get deploy,svc,cm -n edge -l app=edge-relay
```{{exec}}

The ConfigMap appears under its hashed name, the same name as in the render. (The base generator sets the `app: edge-relay` label on it through `options.labels`.)

```bash
kubectl describe deploy edge-relay -n edge
```{{exec}}

Read three lines. `Replicas:` reads 3 desired, from the patch. `Image:` reads nginx:1.27, from the `images` transformer. Under `Environment Variables from:`, the hashed ConfigMap name appears, which matches the ConfigMap that `get` listed.

```bash
kubectl get pods -n edge -l app=edge-relay -o wide
```{{exec}}

Three Pods `Running` on the worker node. The component's `nodeAffinity` requires `disktype=ssd`, and the worker carries that label.
