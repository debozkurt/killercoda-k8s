# Done

The DaemonSet rolled out "successfully" — one Pod, Running, Ready, no errors — and was wrong the whole time. On a 2-node cluster a node-local agent should show `DESIRED 2`; `rtp-probe` showed `1` because its Pod template lacked the control-plane toleration that `sbc-edge` carries. An untolerated node isn't a candidate, so the controller never even tried to place a Pod there — no `Pending`, no event, just a silently uncovered node. Adding the toleration made the node eligible and a second Pod appeared on it.

Two things worth keeping: **a DaemonSet's `DESIRED` is a coverage check, not a replica count** — compare it to your node count, and when it's short, read the Pod's tolerations against the missing node's taints; and **this class of bug is silent** — no red status ever appears, so you catch it by verifying coverage, not by waiting for an alert.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § DaemonSets: one Pod per node.
- You've now broken and fixed all three guarantees — StatefulSet network identity, StatefulSet ordered lifecycle, and DaemonSet coverage. Revisit `LESSON.md` § Recap to tie them together.
