# Step 2 — Fix it and verify

The image tag is wrong. Restore the working one (`nginx:1.25`).

## Apply the fix

```bash
kubectl set image deployment/metrics-aggregator app=nginx:1.25 -n analytics
```{{exec}}

Or, if you prefer to read and edit the manifest:

```bash
kubectl edit deployment metrics-aggregator -n analytics
# change spec.template.spec.containers[0].image to: nginx:1.25
```

`kubectl set image` is faster for a one-field fix. `kubectl edit` is better when you want to see the full manifest in context.

## Watch the rollout converge

A **rollout** is what a Deployment does when its template changes: it spins up new Pods (under a new ReplicaSet) on the new spec, waits for them to become Ready, then tears down the old ones. `kubectl rollout status` blocks until the new ReplicaSet has the target number of ready Pods.

```bash
kubectl rollout status deployment metrics-aggregator -n analytics
```{{exec}}

You should see `deployment "metrics-aggregator" successfully rolled out` within ~30 seconds.

Confirm the pod is healthy:

```bash
kubectl get pods -n analytics
```{{exec}}

You should see one `Running` pod with `1/1 READY`, `0` restarts.

## Confirm the workload is healthy

```bash
kubectl get pods -n analytics
```{{exec}}

You should see `metrics-aggregator-*` pods Running with `1/1 READY`. The alert would now clear.

For self-grading and the GitOps production fix (`kubectl set image` is triage; the real fix lives in `platform-gitops`), see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m00-foundations/ANSWER-KEY.md). For the diagnostic loop concepts behind this, see [`LESSON.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m00-foundations/LESSON.md).

You're done with breakfix-02. See `finish.md`.
