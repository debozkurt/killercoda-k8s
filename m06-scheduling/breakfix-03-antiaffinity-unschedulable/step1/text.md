# Step 1 — Diagnose the stuck replicas

One replica runs, two are `Pending`. When *some* replicas schedule and others don't, the cause is almost always a rule about where they may go relative to each other.

## See the split

```bash
kubectl get pods -n signaling -l app=sip-director -o wide
```{{exec}}

One Pod is `Running` on the worker; two are `Pending` with no node. The workload clearly *can* schedule — one copy did. So why not the others?

## Read the reason on a Pending replica

```bash
kubectl describe pod -n signaling -l app=sip-director | grep -A6 Events
```{{exec}}

The `FailedScheduling` event reads roughly:

```text
0/2 nodes are available: 1 node(s) didn't match pod anti-affinity rules,
                         1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }.
```

Past the control-plane line, the worker's reason is **`didn't match pod anti-affinity rules`**. A replica already runs there, and this Pod's own rule forbids a second one on the same node.

## Read the rule it's enforcing

```bash
kubectl get deploy sip-director -n signaling \
  -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity}'; echo
```{{exec}}

It's a `requiredDuringSchedulingIgnoredDuringExecution` anti-affinity on `topologyKey: kubernetes.io/hostname` — a *hard* "never two of these on one node." A required per-hostname anti-affinity needs at least as many schedulable nodes as replicas. Count them:

```bash
kubectl get nodes
```{{exec}}

Two nodes, but the control-plane is tainted, so only **one** is schedulable for this Pod. One schedulable node, three replicas that each demand their own — two have nowhere legal to go. The rule is doing exactly what it says; the cluster just can't satisfy it. On to the fix.
