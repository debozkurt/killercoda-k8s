# Done

Cascading deletion is a graph walk. When you delete an owner, the garbage collector deletes every object whose `ownerReferences` names it. `vega-media` had no `ownerReferences`, so deleting `vega` left it behind. With the parent gone, the orphan needed a direct delete. The live children were never at risk, because they carry their references.

Keep two points. The ownerReference is the thread the collector pulls, and an object without one is invisible to it. And orphans fail silently, so you find them by comparing a suspect child with a managed one, or by looking for children whose owner no longer exists. `kubectl delete --cascade=orphan` creates the same state on purpose.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the reasoning, see [`LESSON.md`](../LESSON.md) § Owner references and the object graph.
- Last scenario: **`breakfix-05-finalizer-stuck-terminating`**. The opposite failure: an owner that will not go away.
