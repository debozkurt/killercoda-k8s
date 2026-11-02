# Done

Nothing in the pipeline was broken. The store rotated, the operator synced, and the Secret held the new password. `billing-processor` reads that Secret as an environment variable, which the kubelet set when the container started, before the rotation. A rollout started a new container, and the new container read the current Secret.

The instinct to keep: rotation has two steps, and the status covers only the first. When the pipeline is green and a credential still fails, read what the process holds with `kubectl exec ... printenv`.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § Rotation for the three consumption modes.
- Continue to `breakfix-04-target-write-denied`.
