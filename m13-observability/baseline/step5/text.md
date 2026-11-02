# Step 5 — Restarts: read the instance that died

A container restart creates a new **instance** of the container. `restart-demo` in `analytics` restarted once during setup. Its first instance failed and its second runs.

## See the restart

```bash
kubectl get pod restart-demo -n analytics
```{{exec}}

The RESTARTS column reads 1, and the Pod is Running. Read the container's last state:

```bash
kubectl describe pod restart-demo -n analytics | grep -A6 "Last State"
```{{exec}}

Last State is Terminated with Exit Code 1. That is the instance that died.

## Two reads, two instances

```bash
kubectl logs restart-demo -n analytics
kubectl logs restart-demo -n analytics --previous
```{{exec}}

The first command prints start 2: healthy. It reads the current instance, which looks clean. The second prints start 1: cannot reach upstream, exiting. It reads the instance that died. The crash is in the second output only. When a Pod restarts, run `--previous` before you trust a clean log.

## Logs leave with the Pod, events stay

```bash
kubectl delete pod restart-demo -n analytics
kubectl logs restart-demo -n analytics
kubectl events -n analytics --for pod/restart-demo
```{{exec}}

The log read fails with NotFound. The node removed the log files with the Pod. The events remain until the one-hour TTL: Scheduled, Started, Killing. Events and logs have different lifetimes, and neither is a record you can rely on tomorrow. That is why a platform ships both to a durable store.
