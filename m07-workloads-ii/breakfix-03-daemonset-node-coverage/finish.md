# Done

The rollout finished without error and was wrong the whole time. A node-local agent on a 2-node cluster should show `DESIRED` 2. `rtp-probe` showed 1, because its Pod template lacked the control-plane toleration that `sbc-edge` carries. An untolerated node is not eligible. The controller never tried to place a Pod there, so no `Pending` Pod and no event appeared.

**`DESIRED` is a coverage check, not a replica count.** Compare it with the nodes the agent belongs on. When it is short, compare the Pod's tolerations with the missing node's taints.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § DaemonSets: one Pod per eligible node.
- Next scenario: **`breakfix-04-statefulset-update-halt`**. Back to StatefulSets, with a release that stops partway.
