# Step 2 — Fix it and verify

Make the reference name the generator. The generator name is the established one, so the reference is the side that drifted. Do not create an `edge-relay-conf` ConfigMap by hand: the next config change would leave the Pods on that copy.

```bash
cd /root/edge-relay
sed -i 's/name: edge-relay-conf }/name: edge-relay-config }/' base/deployment.yaml
kubectl kustomize overlays/prod | grep -n edge-relay-conf
```{{exec}}

Both lines now carry the hashed name.

```bash
kubectl apply -k overlays/prod
kubectl rollout status deployment/edge-relay -n edge --timeout=90s
```{{exec}}

## Verify

```bash
kubectl get pods -n edge -l app=edge-relay
```{{exec}}

Three Pods `Running` at 1/1. The changed reference changed the Pod template, so the Deployment rolled to a new ReplicaSet. For self-grading and the full path, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m16-kustomize/ANSWER-KEY.md).
