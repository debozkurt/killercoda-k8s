# Step 3 — PodDisruptionBudgets

Pods go down for two very different reasons. **Involuntary** disruptions just happen — a node crashes, the kernel OOM-kills something. **Voluntary** disruptions are ones *you* trigger: draining a node for a kernel patch, or the cluster autoscaler removing an underused node. A **PodDisruptionBudget (PDB)** puts a floor under voluntary disruptions — it tells the eviction API how many replicas of a workload must stay up while you take some down. The baseline ships one on `route-engine`.

## Read the budget

```bash
kubectl get pdb -n call-routing
```{{exec}}

`route-engine` shows `MIN AVAILABLE 1` and `ALLOWED DISRUPTIONS 1`. That last number is the one that matters operationally: with 2 healthy replicas and `minAvailable: 1`, the budget will permit **one** replica to be evicted at a time. Drain the node it's on and the eviction API lets that one go, keeping the other serving.

## The math behind "allowed disruptions"

```bash
kubectl describe pdb route-engine -n call-routing
```{{exec}}

Read the `Status`: `Current Healthy 2`, `Desired Healthy 1`, `Allowed Disruptions 1`. The rule is exactly `allowedDisruptions = currentHealthy − desiredHealthy` (floored at 0). Here `2 − 1 = 1`. The PDB controller recomputes this continuously as Pods come and go.

## Why it matters for a drain

`kubectl drain` doesn't `kubectl delete` Pods — it calls the **eviction API**, which checks every relevant PDB first and refuses an eviction that would drop a workload below its budget. So a PDB is what makes a rolling node drain *safe*: the drain evicts a replica, waits for the Deployment to bring a fresh one up elsewhere (restoring the budget), then evicts the next.

The trap is setting `minAvailable` too high. If it equals the replica count, `allowedDisruptions` is `0` — the budget can *never* be satisfied while removing a Pod, so a drain blocks forever. You just read a healthy budget (`1`); breakfix-01 is the same budget set to `0`. Next: what actually happens to a Pod the moment it's told to shut down.
