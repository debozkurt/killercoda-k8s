# Done

You toured a healthy Kustomize setup end to end: rendered a base, layered two overlays off it, applied the prod overlay, and watched a generator's content hash turn a config edit into a clean rollout. The four mechanisms you saw — **patches**, **generators**, **transformers** (labels/images/namespace), and a **component** — are the whole toolkit. There is no templating language; it's YAML transformed by YAML, and `kubectl kustomize` shows you the result before you commit to it.

**The one habit to keep:** render before you apply. `kubectl kustomize <dir>` is the difference between "I think this overlay is right" and "I can see exactly what will land."

**Next:**

- For the *why* behind bases, overlays, the hash contract, and the immutable-selector trap, read [LESSON.md](../LESSON.md).
- Then work the three break/fix scenarios — one per layer where Kustomize fails:
  - **`breakfix-01-patch-target-mismatch`** — the render itself errors; nothing reaches the cluster.
  - **`breakfix-02-generator-name-mismatch`** — the render succeeds, the apply succeeds, but the Pod won't start.
  - **`breakfix-03-commonlabels-immutable-selector`** — the render succeeds and the API server rejects the apply.
- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
