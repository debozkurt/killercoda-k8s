# Done

Two consumers, two namespaces, one cause. The RoleBinding that grants the operator read access to the backing store named the wrong ServiceAccount — `secret-operator-ro`, which doesn't exist — so the operator's real identity (`secret-operator`) got no access to `secrets-source`. It couldn't read the store, set every SecretSync to `StoreNotReady`, and materialized nothing, so both consumers sat in `CreateContainerConfigError`. Binding the correct ServiceAccount restored access, and the level-triggered loop rebuilt every Secret on its next pass — no restart.

Two things worth keeping: **a store is a shared dependency, so its failures fan out** — when many syncs fail identically and all name one store, that's one problem at the store layer, not many at the secret layer, so diagnose store-first; and the operator runs as a **ServiceAccount whose access you can prove** — `kubectl auth can-i get secrets -n <store-ns> --as=<the operator's SA>` turns "why is nothing syncing" into a yes/no in one command (RBAC in full: M10).

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § the store's own identity deep dive.
- Continue to **`breakfix-03-rotation-not-propagated`** — this time nothing is broken in the pipeline at all; it's green end to end, and a consumer is *still* wrong.
