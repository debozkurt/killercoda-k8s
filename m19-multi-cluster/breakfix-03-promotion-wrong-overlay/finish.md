# Done

A promotion of `nginx:1.27` to stage landed in prod's overlay instead. The result was a non-monotonic ladder — stage behind prod — where stage never advanced and prod overshot the gate. The value was correct the whole time; it was in the wrong layer, and the layer is the blast radius. You read the ladder, found where the pin actually lived, and *moved* it (advanced stage, unpinned prod) rather than adding a copy.

The reflex to keep: **a healthy promotion ladder is monotonic — a tier is never behind the one after it.** When it isn't, the change landed in the wrong layer; move it to the overlay that owns that step. Promotion is advancing a pin lab → stage → prod, one tier at a time, and the base is reserved for things every cluster must take at once. This is the *right-value-wrong-layer* leaf of the differential.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Promotion and blast radius.
- You've now worked all three ways a fleet value goes wrong — stale in its layer, shadowed by a later layer, and right value in the wrong layer. Re-read [`LESSON.md`](../LESSON.md) to tie the differential together, and see how a GitOps controller renders and delivers these paths in **M18 (Flux)**.
