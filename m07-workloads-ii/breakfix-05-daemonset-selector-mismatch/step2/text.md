# Step 2 — Fix it and verify

A node label is a claim about the hardware. Relabeling the worker `disktype=nvme` would make the DaemonSet roll out and make the label false for every workload that reads it. Correct the selector instead.

## Correct the selector

```bash
kubectl patch daemonset disk-exporter -n media \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"disktype":"ssd"}}}}}'
```{{exec}}

Or by hand:

```bash
kubectl edit daemonset disk-exporter -n media
# under spec.template.spec.nodeSelector: disktype nvme -> ssd
```

## Verify

```bash
kubectl get daemonset disk-exporter -n media
kubectl get pods -n media -l app=disk-exporter -o wide
```{{exec}}

`DESIRED` is now 1, and one Pod runs on the worker. That is the correct number. The agent belongs on fast-disk nodes, and the worker is the only one. The control-plane node is correctly uncovered. In breakfix-03 the right answer was 2. The right number is always the nodes the agent belongs on.

See [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m07-workloads-ii/ANSWER-KEY.md) for self-grading, then `finish.md`.
