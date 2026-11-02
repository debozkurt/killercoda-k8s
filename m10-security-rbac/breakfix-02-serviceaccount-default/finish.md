# Done

The same 403 had a different cause. The Role and RoleBinding granted `route-watcher` what it needed. The Pod template omitted `serviceAccountName`, so the Pod ran as `default`, which holds no grant. The identity field in the Forbidden named `default`, and that field was the diagnosis.

The question to ask of every 403: **is the permission wrong, or is the caller not the one you meant?** Here it was the caller, so the fix was one field on the Pod. A grant to `default` would have reached every Pod in the namespace that omits the field.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-03-rbac-cluster-scope`**. The verb and identity are right, and the scope is wrong.
