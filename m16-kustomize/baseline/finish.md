# Done

You rendered a base, compared two overlays built from it, compared prod with the live cluster through `kubectl diff -k`, and changed one config value. The hash gave the ConfigMap a new name, the new name changed the Pod template, and the Deployment rolled. The old ConfigMap stayed until `--prune` removed it.

The habit to keep: **render before you apply, and diff before you apply to a live workload.**

**Next:**

- For the model behind bases, overlays, patch targets, the hash, and the immutable selector, read [LESSON.md](../LESSON.md).
- Then work the five break/fix scenarios, starting with **`breakfix-01-patch-target-mismatch`**.
- Check each one against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
