# Done

Cascading deletion is not magic — it's a graph walk. When you delete an owner, the garbage collector finds every object whose `ownerReferences` names that owner and deletes them too. `vega-media` had **no** ownerReferences (an older operator created it before owner-reference stamping), so when the `vega` MediaTenant was deleted there was no link tying them together — the child was orphaned, not collected, and kept holding capacity indefinitely. With the parent already gone there was no cascade left to trigger, so the orphan had to be deleted directly. The live children, `orion-media` and `lyra-media`, were never at risk: they carry their owner references and will clean up automatically when their tenants are offboarded.

Two things worth keeping: **the ownerReference is the thread cascading deletion pulls** — a child without one is invisible to the garbage collector and becomes a silent orphan when its logical parent is deleted; and **orphans hide in plain sight** — nothing errors, the resource just runs on, so you find them by comparing a suspect child's `ownerReferences` to a properly-managed one's, and by watching for children whose owner no longer exists.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Owner references and the object graph.
- You've now broken and fixed all three links: the resource that won't apply, the operator that won't reconcile, and the cleanup that won't cascade. Revisit `LESSON.md` § Recap to tie them together.
