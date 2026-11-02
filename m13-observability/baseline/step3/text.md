# Step 3 — Resource metrics: `kubectl top`

The first metrics pipeline is the **Resource Metrics API**. **metrics-server** collects live CPU and memory from each kubelet and serves them on `metrics.k8s.io`. `kubectl top` reads it.

## Usage right now

```bash
kubectl top nodes
```{{exec}}

If it reports that the Metrics API is not available, metrics-server is still starting. Wait 30 seconds and run it again. The output shows CPU and memory in use per node.

```bash
kubectl top pods -A --sort-by=memory | head -12
```{{exec}}

The biggest memory users are first. The **HPA** (Horizontal Pod Autoscaler) scales on this same data.

## Read usage against the request

A **request** is the CPU and memory a Pod asks the scheduler to reserve. Usage means little without it:

```bash
kubectl top pod -n media -l app=session-broker
kubectl describe deployment session-broker -n media | grep -A2 Requests
```{{exec}}

The first command prints usage. The second prints the request. "How loaded is this" is the ratio of the two. The HPA divides them the same way.

## The limits of this pipeline

The pipeline reports CPU and memory only, and only the present. It keeps no history and no custom numbers. Without metrics-server both `kubectl top` and the HPA fail.

Anything richer, such as calls per second or queue depth, comes from a different pipeline that the workload publishes itself. That is next.
