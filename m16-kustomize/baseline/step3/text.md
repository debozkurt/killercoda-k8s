# Step 3 — Apply and observe

The setup already applied the prod overlay. Re-run the apply yourself — it's the command you'd use in a pipeline, and it's idempotent:

```bash
kubectl apply -k overlays/prod
```{{exec}}

`apply -k <dir>` is exactly `kubectl kustomize <dir>` piped into `kubectl apply -f -`: build the overlay, then apply the result. The second run reports `unchanged` for objects already in their desired state — the render matched what's live.

## What actually landed

The cluster holds the *rendered* objects, not the kustomization. It has no idea Kustomize exists:

```bash
kubectl get deploy,svc,cm -n edge -l app=edge-relay
```{{exec}}

You see the Deployment (3 replicas, from the patch), the Service, and the ConfigMap under its **hashed** name — the same name you saw in step 2's render. Confirm the running Pods and the prod tag:

```bash
kubectl get pods -n edge -l app=edge-relay -o wide
kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```{{exec}}

Three Pods `Running`, image `nginx:1.27` — the overlay's image pin. The Pods landed on the SSD worker because the `regional-affinity` component added a `nodeAffinity` for `disktype=ssd`.

## The reference held end to end

The whole point of the hash-suffix machinery is that the Deployment references the exact ConfigMap that exists. Check that the live Deployment's `envFrom` names a ConfigMap that's actually present:

```bash
REF=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
echo "Deployment references: $REF"
kubectl get configmap "$REF" -n edge
```{{exec}}

The reference resolves — `apply -k` wrote the hashed name into both the ConfigMap *and* the Deployment, so they agree. When that agreement breaks, the Pod can't start; that's `breakfix-02`. Step 4 shows *why* the name carries a hash at all.
