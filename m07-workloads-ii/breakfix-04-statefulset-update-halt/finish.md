# Done

The release named an image tag that does not exist. `RollingUpdate` replaced the highest ordinal first, and `session-store-2` never became Ready. The controller stopped there. Ordinals 0 and 1 stayed on the old revision, so the cache kept serving with two of three members. The reverse order limited the damage.

The repair took two steps. `kubectl rollout undo` restored the template. A manual delete replaced the Pod that still ran the bad one, because the controller does not repair an un-Ready Pod on its own.

To contain the next release further, set `partition` before you push. With `partition: 2`, only ordinal 2 updates. You verify it, then lower the partition to widen the rollout.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Ordered lifecycle.
- Last scenario: **`breakfix-05-daemonset-selector-mismatch`**. A DaemonSet that rolls out clean and creates no Pod.
