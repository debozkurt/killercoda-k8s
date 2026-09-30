# Step 2 — Fix it and verify

This cluster has one schedulable node, so a hard one-per-node rule can never hold 3 replicas. Soften it: `preferred` keeps the spread as a weighted preference, and the scheduler still places the Pods when it cannot spread them.

## Soften the anti-affinity

```bash
kubectl patch deployment sip-director -n signaling --type=json -p '[
  {"op":"remove","path":"/spec/template/spec/affinity/podAntiAffinity/requiredDuringSchedulingIgnoredDuringExecution"},
  {"op":"add","path":"/spec/template/spec/affinity/podAntiAffinity/preferredDuringSchedulingIgnoredDuringExecution","value":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchLabels":{"app":"sip-director"}},"topologyKey":"kubernetes.io/hostname"}}]}
]'
```{{exec}}

## Watch the rollout stall

Give the rollout 20 seconds:

```bash
kubectl rollout status deployment/sip-director -n signaling --timeout=20s
kubectl get pods -n signaling -l app=sip-director -o wide
```{{exec}}

The rollout times out. A new Pod from the new ReplicaSet is `Pending` too. Read its event:

```bash
kubectl describe pod -n signaling -l app=sip-director | grep 'anti-affinity'
```{{exec}}

A new reason appears: `didn't satisfy existing pods anti-affinity rules`. Required anti-affinity works in both directions. The old running Pod still carries the hard rule, and its rule repels every Pod labeled `app: sip-director`, including its own replacement.

The Deployment controller will not remove that old Pod either. With 3 replicas, the default `maxUnavailable` of 25% rounds down to 0 Pods. So neither side moves.

## Clear the old Pods

Stop every replica, then start 3 from the new template:

```bash
kubectl scale deployment sip-director -n signaling --replicas=0
kubectl wait --for=delete pod -n signaling -l app=sip-director --timeout=60s
kubectl scale deployment sip-director -n signaling --replicas=3
```{{exec}}

This is a short, full outage of the service. On a cluster with a spare node, the new Pods land beside the old ones, and no stall occurs.

## Verify

```bash
kubectl get pods -n signaling -l app=sip-director -o wide
kubectl get deploy sip-director -n signaling
```{{exec}}

All three Pods are `Running` on the worker, and the Deployment reports `3/3`.

## The trade-off

All three replicas now share one node, so one node failure takes out all three. That is the risk the hard rule existed to prevent. It is the right call here only because the alternative is two replicas `Pending` forever. The durable choice depends on intent:

- **One-per-node is a real requirement?** Add schedulable nodes, so the `required` rule can hold.
- **Best-effort spread is enough?** `preferred`, or a topology spread with `ScheduleAnyway`, is correct.
- **Fewer replicas are acceptable?** Scaling to 1 also clears the `Pending` Pods, at the cost of redundancy.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). Then see `finish.md`.
