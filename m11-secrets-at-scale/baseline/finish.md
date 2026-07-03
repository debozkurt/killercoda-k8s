# Done

You read a healthy secrets pipeline end to end: a **backing store** (`vault-backend`) standing in for an external secrets manager, two **SecretSync** objects that *name* store keys without containing them, the **secret-operator** reconcile loop that materialized a Kubernetes **Secret** for each and reported `Synced` in `.status`, and the **consumers** running on those Secrets — the value traced all the way from the store to the process's environment. That's the shape of "the supply chain is intact."

The one idea to carry forward: at scale a Secret is a **derived object**, produced by a controller from a source of truth. A consumer that can't get its credential now has causes *upstream* of the Pod — the store, the reference, the operator's access — and you find them by reading the pipeline's own `.status`, not the Pod's logs.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each snaps one link in this chain:
  - **`breakfix-01-source-key-missing`** — a SecretSync in `SyncError`: its reference names a store key that doesn't exist, so no Secret is produced and the consumer can't start.
  - **`breakfix-02-store-access-denied`** — every sync `StoreNotReady` at once: the operator lost read access to the backing store, so the whole pipeline is down.
  - **`breakfix-03-rotation-not-propagated`** — a green pipeline and a stale consumer: the store rotated, the Secret updated, but the running Pod still holds the old value.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
