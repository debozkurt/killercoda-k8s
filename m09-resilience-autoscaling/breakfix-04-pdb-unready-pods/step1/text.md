# Step 1 — Diagnose the refused eviction

The floor is 1 of 2. Read the budget's inputs, not just its result.

## Read the budget

```bash
kubectl get pdb -n signaling
kubectl describe pdb trunk-monitor -n signaling
```{{exec}}

`ALLOWED DISRUPTIONS` reads 0. In `describe`, read `Min available:` (1) and then the `Status:` block. `Desired:` is 1, `Total:` is 2, and `Current:` is 0. Current counts healthy Pods, and a healthy Pod is a Ready one. No replica is Ready, so Current is 0, and 0 − 1 floors at 0.

## Find why no Pod is healthy

```bash
kubectl get pods -n signaling -l app=trunk-monitor
```{{exec}}

Both Pods are `Running` and read 0/1 under READY. Running is not Ready. Read one Pod by name, because a label selector prints both Pods and hides which events belong to which:

```bash
POD=$(kubectl get pods -n signaling -l app=trunk-monitor -o name | head -1)
kubectl describe $POD -n signaling
```{{exec}}

In `Events:`, find `Readiness probe failed: HTTP probe failed with statuscode: 404`. In the container block, find the `Readiness:` line: it probes /healthz on port 80. nginx serves /, not /healthz.

## See the refusal

The unready Pods are not serving, yet the eviction API still refuses them:

```bash
NAME=$(echo $POD | cut -d/ -f2)
cat <<EOF > /tmp/evict.json
{"apiVersion":"policy/v1","kind":"Eviction","metadata":{"name":"$NAME","namespace":"signaling"}}
EOF
kubectl create --raw "/api/v1/namespaces/signaling/pods/$NAME/eviction" -f /tmp/evict.json
```{{exec}}

```text
Error from server (TooManyRequests): Cannot evict pod as it would violate the pod's disruption budget.
```

The default `unhealthyPodEvictionPolicy` is `IfHealthyBudget`. It lets the API evict an unready Pod only while the budget is healthy, meaning `Current:` is at least `Desired:`. Here Current is 0, so the broken Pods block their own removal. Next: repair the cause.
