# Step 4 — Apply and observe

The setup already applied `prod-us-east-1`. Re-run the apply yourself — it's the command a pipeline runs, and it's idempotent:

```bash
cd /root/fleet
kubectl apply -k clusters/prod-us-east-1
```{{exec}}

`apply -k <dir>` is `kubectl kustomize <dir>` piped into `kubectl apply -f -`: render the cluster, then apply the result. The second run reports `unchanged` — the render matched what's live.

## What actually landed

The cluster holds the *rendered* objects, not the fleet repo. It has no idea Kustomize (or a fleet) exists:

```bash
kubectl get deploy,svc,cm -n edge -l app=edge-relay
```{{exec}}

The Deployment (3 replicas, from the leaf patch), the Service, and the ConfigMap under its hashed name. Confirm the running Pods and the prod image:

```bash
kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.replicas} replicas, image {.spec.template.spec.containers[0].image}{"\n"}'
kubectl get pods -n edge -l app=edge-relay
```{{exec}}

Three Pods `Running` on `nginx:1.25` — prod hasn't taken `1.27` yet, exactly as the render said.

## The reference held end to end

Check that the live Deployment's `envFrom` names a ConfigMap that actually exists — the hash machinery from M16, holding across three layers:

```bash
REF=$(kubectl get deploy edge-relay -n edge -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
echo "Deployment references: $REF"
kubectl get configmap "$REF" -n edge
```{{exec}}

The reference resolves. In production you wouldn't apply each cluster by hand — a GitOps controller (Flux, M18) renders every cluster's path and applies it, and fans out across real clusters. Here one cluster stands in for the fleet. That's the healthy machine end to end. Now go break it — the three scenarios each fault one layer of the composition.
