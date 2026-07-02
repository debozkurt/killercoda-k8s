# Done

`call-coordinator`'s Pods were both `Running`, but no leader was ever elected and no Lease was held — the workload was up but idle. Leadership is a lock on a `coordination.k8s.io` Lease, and taking that lock requires permission. The `leader-election` Role granted only `list` and `watch` on `leases`, missing the `get`, `create`, and `update` the election client needs, so it was forbidden from the lock and could never lead. `auth can-i --as` proved it in one line; restoring the verbs (a Role is mutable, so a plain re-apply) made the lock acquirable again.

The lesson: **a leaderless singleton with healthy Pods is almost always an RBAC problem on the lock object, not a Pod problem.** Check the Lease and the election client's permission before you touch the Pods.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Leader election with Leases.
- You've now snapped and repaired all three links of the coordination stack — identity/lifecycle, discovery, and leadership. Revisit [`LESSON.md`](../LESSON.md) § Production thinking to tie them together.
