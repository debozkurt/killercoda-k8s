# Step 2 — Fix it and verify

The rule is right; the cluster can't honor it *hard*. On a cluster with only one schedulable node, soften the anti-affinity from `required` to `preferred` — the scheduler still spreads replicas when it can, but packs them in rather than leaving them `Pending`.

## Soften the anti-affinity to best-effort

```bash
kubectl patch deployment sip-director -n signaling --type=json -p '[
  {"op":"remove","path":"/spec/template/spec/affinity/podAntiAffinity/requiredDuringSchedulingIgnoredDuringExecution"},
  {"op":"add","path":"/spec/template/spec/affinity/podAntiAffinity/preferredDuringSchedulingIgnoredDuringExecution","value":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchLabels":{"app":"sip-director"}},"topologyKey":"kubernetes.io/hostname"}}]}
]'
```{{exec}}

`preferred` keeps the spread as a weighted preference: give it more nodes and it distributes; give it one, it still schedules. The new Pods roll out and land on the worker.

## Verify

```bash
kubectl get pods -n signaling -l app=sip-director -o wide
kubectl get deploy sip-director -n signaling
```{{exec}}

All three Pods are `Running` (all on the worker for now); the Deployment reports `3/3`.

## The trade-off to understand

Softening trades a *guarantee* for a *preference*: on this one-node cluster all three replicas now share a node, so a node failure would take out all three — the very thing the rule was meant to prevent. That's the honest cost, and it's the right call only because the alternative (two replicas permanently `Pending`) is worse. The durable fix depends on intent:

- **Truly need one-per-node HA?** Add schedulable nodes (or tolerate more of them) so a `required` rule can be satisfied.
- **Best-effort spread is fine?** `preferred` (or a `ScheduleAnyway` topology spread) is correct.
- **Fewer replicas acceptable?** `kubectl scale deploy sip-director -n signaling --replicas=1` also clears the `Pending`, at the cost of redundancy.

For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
