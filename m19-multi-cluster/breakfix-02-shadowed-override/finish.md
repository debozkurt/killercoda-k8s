# Done

The region overlay was raised to `8000` and the cluster still ran `5000`, because a leftover per-cluster `configMapGenerator` override sat later in the composition stack and won. Editing the region — the file you'd naturally reach for — changed nothing, because a more-specific layer was shadowing it. You found it by grepping the field up the whole path and taking the *last* writer, then deleting the shadow so the owning layer's value flowed through.

The reflex to keep: **if editing the layer that "owns" a value doesn't change the render, a later layer is winning — grep the whole path and take the last writer.** Composition order is base → region → cluster, and the most-specific layer always wins. This is the *shadowed-by-a-later-layer* leaf of the differential; contrast it with break/fix 01, where the owning layer itself was stale.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Rendering trace and composition order.
- Next scenario: **`breakfix-03-promotion-wrong-overlay`** — the value is correct, but it landed in the wrong layer entirely.
