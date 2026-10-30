# Done

`disk-exporter` rolled out with no error and covered nothing. Its `nodeSelector` asked for `disktype=nvme`, a label from another region's node pool. No node here carries it, so the controller found no eligible node and created no Pod. `DESIRED` read 0, with no `Pending` Pod and no event. A Deployment with the same selector would have left a `Pending` Pod and a `FailedScheduling` event.

You corrected the selector to the label the hardware carries, and left the node alone. `DESIRED` 1 is correct here, because only one node has a fast disk. A coverage check compares `DESIRED` with the nodes the agent belongs on, not always with the node count.

You have now broken both StatefulSet guarantees that fail quietly, and both DaemonSet coverage causes.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § DaemonSets: one Pod per eligible node.
- You have completed M07. Revisit `LESSON.md` § Recap to tie the five scenarios together.
