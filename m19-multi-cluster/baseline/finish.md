# Done

You toured a healthy fleet repo end to end: read a three-layer tree (base → region → cluster), rendered two clusters and traced each field to the layer that set it, watched the image `1.27` sit promoted through lab and stage while prod still ran the base default, and applied one cluster to confirm the API server holds only rendered objects. One base, evaluated once per cluster — the whole fleet described in one repo, no templating language.

**The one habit to keep:** `kubectl kustomize clusters/<cluster>` renders exactly what that cluster gets, and a value is attributed by grepping its layer path — the last layer that sets a field wins.

**Next:**

- For the *why* behind fleet layers, cluster variables, composition order, and promotion, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios — one per layer where a value goes wrong:
  - **`breakfix-01-stale-cluster-var`** — a value is stale in its owning layer (a cloned region overlay).
  - **`breakfix-02-shadowed-override`** — a value is shadowed by a later layer that wins.
  - **`breakfix-03-promotion-wrong-overlay`** — the right value landed in the wrong layer.
- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
