# Done

Same symptom as breakfix-01 — a `Pending` Pod — but the `FailedScheduling` event told a different story: `untolerated taint {dedicated: telephony}`. The node wasn't short on anything; it had been marked to repel Pods that don't opt in, and `pstn-probe` hadn't. The fix was a single toleration matching the taint's key, value, and effect — the same mechanism `sbc-edge` uses to reach the control-plane node.

Two things worth keeping: **taints live on the node** (`describe node`, not `describe pod`, is where you find them), and **`NoSchedule` doesn't evict** — the running fleet stayed put on the tainted node; only new scheduling was blocked. A `NoExecute` taint would have emptied it.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Taints and tolerations.
- Next scenario: **`breakfix-03-antiaffinity-unschedulable`** — the resources fit and no taint is in the way, yet some replicas *still* won't schedule.
