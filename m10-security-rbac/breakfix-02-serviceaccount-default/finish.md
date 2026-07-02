# Done

Same 403, different root cause. The Role and RoleBinding were correct — they granted `route-watcher` exactly what it needed — but the Pod omitted `serviceAccountName`, so it ran as the namespace `default` SA, which is bound to nothing. The Forbidden named `...:default`, not `route-watcher`, and that one word was the whole diagnosis: **is the permission wrong, or is the caller not who you think?** Here it was the caller. The fix was one field on the Pod, not a line of RBAC.

The trap you avoided: "fixing" it by granting `default` the permission. That works — and it silently grants the same access to *every* Pod in the namespace that also runs as `default`. Give a workload its own SA and bind that.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § ServiceAccounts.
- Next scenario: **`breakfix-03-rbac-cluster-scope`** — a 403 whose *scope*, not its verb or identity, is the problem.
