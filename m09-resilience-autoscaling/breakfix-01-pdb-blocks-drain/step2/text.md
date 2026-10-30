# Step 2 — Fix it, then check what a drain needs

## Give the budget headroom

With 2 replicas, a floor of 1 keeps one Pod serving and allows the other to go. Allowed disruptions becomes 2 − 1 = 1.

```bash
kubectl patch pdb sip-registrar -n signaling --type merge -p '{"spec":{"minAvailable":1}}'
kubectl get pdb sip-registrar -n signaling
```{{exec}}

ALLOWED DISRUPTIONS reads 1. Repeat the eviction from step 1. It now passes, and the Deployment starts a replacement:

```bash
POD=$(kubectl get pod -n signaling -l app=sip-registrar -o jsonpath='{.items[0].metadata.name}')
cat <<EOF > /tmp/evict.json
{"apiVersion":"policy/v1","kind":"Eviction","metadata":{"name":"$POD","namespace":"signaling"}}
EOF
kubectl create --raw "/api/v1/namespaces/signaling/pods/$POD/eviction" -f /tmp/evict.json; echo
kubectl wait --for=condition=Ready pod -l app=sip-registrar -n signaling --timeout=60s
```{{exec}}

## The budget is not the only gate

A real drain cordons the worker first, which stops new Pods from landing on it. This cluster has one schedulable node, so a replacement has nowhere else to go. Cordon the worker and evict one Pod:

```bash
WORKER=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o name)
kubectl cordon $WORKER
POD=$(kubectl get pod -n signaling -l app=sip-registrar -o jsonpath='{.items[0].metadata.name}')
cat <<EOF > /tmp/evict.json
{"apiVersion":"policy/v1","kind":"Eviction","metadata":{"name":"$POD","namespace":"signaling"}}
EOF
kubectl create --raw "/api/v1/namespaces/signaling/pods/$POD/eviction" -f /tmp/evict.json; echo
```{{exec}}

Wait 20 seconds, then read the Pods and the budget:

```bash
kubectl get pods -n signaling -l app=sip-registrar
kubectl get pdb sip-registrar -n signaling
```{{exec}}

The replacement is `Pending`, and ALLOWED DISRUPTIONS is back to 0. One healthy Pod remains, and the floor is 1. The drain stalls again, now on capacity instead of the budget. A drain needs room for each replacement to become Ready elsewhere.

Uncordon the worker so the replacement lands:

```bash
kubectl uncordon $WORKER
kubectl wait --for=condition=Ready pod -l app=sip-registrar -n signaling --timeout=60s
```{{exec}}

`maxUnavailable: 1` says "one at a time" with no replica count in it, which suits an HPA-driven workload. Do not delete the PDB to unblock a drain: that removes the protection.

See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m09-resilience-autoscaling/ANSWER-KEY.md) for self-grading, then `finish.md`.
