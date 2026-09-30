# Done

The `FailedScheduling` event named the filter: `didn't match Pod's node affinity/selector`. The Pod's `nodeSelector` asked for `disktype=nvme`, a label from another region's node pool. No node here carries it, so the hard filter removed every node. The fix corrected the selector to the label the hardware really carries, and left the node alone.

With this scenario, you have read every branch of the `Pending` differential: untolerated taint, unmatched node affinity, insufficient resources, and an unsatisfiable spread. Each branch has its own entry in one event, and each has its own fix.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Steering and spreading.
- You have completed M06. Next module: **M07 — Workloads II (StatefulSets & DaemonSets)**, which builds on the node-local placement you read here.
