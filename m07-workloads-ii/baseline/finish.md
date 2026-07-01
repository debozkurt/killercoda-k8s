# Done

You read both non-Deployment controllers on the healthy fleet: the StatefulSets' three guarantees — ordinal names (`media-engine-0`/`-1`), the headless Service that gives each ordinal a stable per-Pod DNS record, and the sticky `state-<sts>-<ordinal>` PVCs that follow each ordinal — and the `sbc-edge` DaemonSet covering both nodes, reaching the tainted control-plane through a toleration. That's the shape of "the guarantee held" — internalize it so each break stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each breaks exactly one guarantee:
  - **`breakfix-01-headless-service-missing`** — Pods Running, but `pod-0.svc` won't resolve: the governing headless Service was never created.
  - **`breakfix-02-ordered-rollout-stall`** — `READY 0/3`, only Pod-0 present: `OrderedReady` blocked behind an un-ready Pod-0.
  - **`breakfix-03-daemonset-node-coverage`** — a node-local agent reports `DESIRED 1` on a 2-node cluster: a missing toleration, silently uncovering a node.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
