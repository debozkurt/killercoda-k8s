# Step 1 — Walk from the HPA to the missing Pods

Start at the HPA and move down one object at a time.

## The HPA

```bash
kubectl get hpa -n captions
kubectl describe hpa caption-engine -n captions
```{{exec}}

TARGETS reads a real percentage, MINPODS reads 4, and REPLICAS reads 2. In `describe`, the `Deployment pods:` line reads 2 current / 4 desired, and `ScalingActive` is `True`. The HPA works and wants 4 Pods. It cannot see why they do not exist.

## The Deployment

```bash
kubectl get deployment caption-engine -n captions
kubectl get pods -n captions
```{{exec}}

READY reads 2/4. Two Pods exist, and no Pod is `Pending`. A Pod that the scheduler could not place would show up as `Pending`. These two Pods were never created.

## The refusal

```bash
kubectl get events -n captions --sort-by=.lastTimestamp
```{{exec}}

Find `FailedCreate` events from the ReplicaSet. The message ends with `exceeded quota: pod-cap, requested: pods=1, used: pods=2, limited: pods=2`. Admission refused the Pods.

```bash
kubectl describe resourcequota pod-cap -n captions
```{{exec}}

Read the `pods` row: Used 2, Hard 2. A **ResourceQuota** caps what a namespace can hold, and the cap sits below the HPA's minimum of 4. Next: raise it.
