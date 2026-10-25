# Step 2 — Fix it and verify

Two valid fixes. Pick based on intent:

- **Raise the quota** — if 3 replicas is the right answer and the quota was set too low
- **Reduce replicas** — if 2 was the intended replica count and someone bumped it by mistake

In a real incident with no other context, either gets the alert to clear. The choice is a *production* question (covered below). For this scenario, raise the quota — it's the more useful pattern to know.

## Raise the quota

Raising to **3** — exactly enough to satisfy the Deployment, no slack. (Adding headroom like `5` is a judgment call; in production you'd justify the bump via capacity review. For triage, match the actual demand.)

```bash
kubectl patch resourcequota pod-limit -n number-porting --type=merge \
  -p '{"spec":{"hard":{"pods":"3"}}}'
```{{exec}}

Or with `kubectl edit`:

```bash
kubectl edit resourcequota pod-limit -n number-porting
# change spec.hard.pods from "2" to "3"
```

> ⚠️ `kubectl edit` opens both `spec` and `status`. Change **`spec.hard.pods`** — `status.hard.pods` is controller-managed and edits to it get reverted within a second. The same `spec` (yours) / `status` (controller's) split applies to every Kubernetes object.

## Watch the third pod schedule

```bash
kubectl get pods -n number-porting -w
```{{exec}}

You should see the third pod appear, transition through `Pending → ContainerCreating → Running`. Once you see all three Running, `Ctrl-C` to exit the watch.

## Verify

```bash
kubectl get deploy port-processor -n number-porting
```{{exec}}

`READY 3/3`. The deployment is satisfied.

```bash
kubectl get events -n number-porting --sort-by='.lastTimestamp' | tail -5
```{{exec}}

Recent events should show `SuccessfulCreate` instead of `FailedCreate`.

For self-grading and the production answer (raise the quota vs revert the replica bump — `kubectl patch` is triage, the real fix lives in GitOps), see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m00-foundations/ANSWER-KEY.md). For the resource model and owner-chain concepts, see [`LESSON.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m00-foundations/LESSON.md).

You're done with breakfix-03. See `finish.md`.
