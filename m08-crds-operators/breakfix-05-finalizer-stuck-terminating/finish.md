# Done

The tenant carried a finalizer, `polyphone.example/media-cleanup`. The API server set `deletionTimestamp` and held the object in `Terminating`. The controller that owns the finalizer was scaled to zero, so nobody ran the cleanup or removed the key. Scaling the operator back let it finish, and the garbage collector then removed `vega-media`.

Keep two points. A finalizer is a promise that a controller will clean up before the object disappears, so a delete that hangs points at the controller that owns the key. And removing the key by hand ends the hang while it skips the cleanup. The same pattern wedges a namespace delete when an operator is uninstalled before its custom resources.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the reasoning, see [`LESSON.md`](../LESSON.md) § Finalizers.
- Return to [`LESSON.md`](../LESSON.md) § Recap to join the five links: type, loop, version, owner reference and finalizer.
