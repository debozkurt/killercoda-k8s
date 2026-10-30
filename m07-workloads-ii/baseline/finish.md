# Done

You read both non-Deployment controllers on a healthy fleet. A StatefulSet names its Pods by ordinal, resolves each one through a headless Service, and gives each its own claim. You deleted `media-engine-0` and watched the name, the claim and the data return. You scaled `media-engine` down and up, and the claim stayed. The `sbc-edge` DaemonSet covers both nodes, and its toleration is the reason it reaches the control-plane node.

That is the shape of a guarantee that held. Learn it, so each broken guarantee stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the five break/fix scenarios, in order. Each breaks one guarantee:
  - **`breakfix-01-headless-service-missing`** — Pods `Running`, but the per-Pod name returns `NXDOMAIN`: nobody created the governing Service.
  - **`breakfix-02-ordered-rollout-stall`** — `READY 0/3` with one Pod: `OrderedReady` waits on an un-Ready ordinal 0, and the fix needs a manual delete.
  - **`breakfix-03-daemonset-node-coverage`** — `DESIRED 1` on a 2-node cluster: a missing toleration leaves a node uncovered.
  - **`breakfix-04-statefulset-update-halt`** — a bad release halts at the highest ordinal, and the lower ordinals keep the old revision.
  - **`breakfix-05-daemonset-selector-mismatch`** — `DESIRED 0` and no Pod: a selector for a label no node carries.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
