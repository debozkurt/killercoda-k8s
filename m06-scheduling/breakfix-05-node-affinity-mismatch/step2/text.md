# Step 2 — Fix it and verify

Two changes would get the Pod a node. Only one is honest. A node label is a claim about the hardware. Relabeling the worker `disktype=nvme` would make the Pod schedule and make the label lie to every other workload. Correct the Pod's selector instead.

## Correct the selector

A merge patch replaces the value in the Pod template:

```bash
kubectl patch deployment conference-mixer -n media \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"disktype":"ssd"}}}}}'
```{{exec}}

The template change rolls a new Pod.

Or by hand:

```bash
kubectl edit deployment conference-mixer -n media
# under spec.template.spec.nodeSelector: disktype nvme -> ssd
```

## Verify

```bash
kubectl get pods -n media -l app=conference-mixer -o wide
kubectl get deploy conference-mixer -n media
```{{exec}}

The new Pod lands on the worker and reaches `Running`, and the Deployment reports `1/1`. Read its events:

```bash
kubectl describe pod -n media -l app=conference-mixer
```{{exec}}

`Node-Selectors:` reads `disktype=ssd`, and the last event is `Scheduled`. The node did not change. The Pod now asks for a label that exists.

One more property of node affinity: it is `IgnoredDuringExecution`. If someone removes the `disktype` label from the worker now, the running Pod stays. Only the next placement feels the change.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). Then see `finish.md`.
