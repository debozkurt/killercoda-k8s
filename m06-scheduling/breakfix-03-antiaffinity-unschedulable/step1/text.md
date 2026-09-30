# Step 1 — Diagnose the stuck replicas

One replica runs and two are `Pending`. When some replicas of one workload schedule and others do not, suspect a rule about where they may go relative to each other.

## See the split

```bash
kubectl get pods -n signaling -l app=sip-director -o wide
```{{exec}}

One Pod is `Running` on the worker. Two are `Pending`, with `<none>` in the `NODE` column. The workload can schedule, because one copy did.

## Read the reason on a Pending replica

```bash
kubectl describe pod -n signaling -l app=sip-director
```{{exec}}

The output covers all three Pods. On a `Pending` one, the `FailedScheduling` event reads:

```text
0/2 nodes are available: 1 node(s) didn't match pod anti-affinity rules,
1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: ...
```

Past the control-plane entry, the worker's reason is **`didn't match pod anti-affinity rules`**. A replica already runs on the worker, and this Pod's own rule forbids a second one there.

## Read the rule it enforces

The Deployment YAML is long, so filter to the rule:

```bash
kubectl get deploy sip-director -n signaling -o yaml | grep -A6 podAntiAffinity
```{{exec}}

The rule is `requiredDuringSchedulingIgnoredDuringExecution`, with `topologyKey: kubernetes.io/hostname` and a selector on `app: sip-director`. In plain terms: never two of these Pods on one node. A required rule on hostname needs at least as many schedulable nodes as replicas. Count them:

```bash
kubectl get nodes
```{{exec}}

Two nodes, and the control-plane taint repels this Pod, so one node is schedulable. One node, three replicas that each demand their own: two have nowhere legal to go. The rule works exactly as written. The cluster cannot satisfy it.

Next: soften the rule, and watch what the old Pods do to the rollout.
