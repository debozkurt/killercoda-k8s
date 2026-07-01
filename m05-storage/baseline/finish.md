# Done

You walked the durable-storage chain end to end: a `Bound` PVC and the PV a StorageClass provisioned for it, the `WaitForFirstConsumer` binding that holds a consumer-less claim `Pending` on purpose, an RWO volume pinned to one node with data that survived a Pod delete, and the `get pvc` triage that splits any storage-stuck Pod three ways. That's the shape of "healthy" — internalize it so each broken link stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — together they walk the **storage differential** top to bottom, one `get pvc` signature each:
  - **`breakfix-01-pvc-storageclass-missing`** — PVC `Pending`: the claim can't bind because its StorageClass doesn't exist.
  - **`breakfix-02-pvc-claim-missing`** — claim absent: the Pod names a PVC that isn't there.
  - **`breakfix-03-rwo-multi-attach`** — PVC `Bound`, Pod still stuck: an RWO volume asked to span two nodes.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
