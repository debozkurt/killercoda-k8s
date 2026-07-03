# Done

The `partner-api` Secret was missing not because someone deleted it, but because the pipeline never produced it: the SecretSync named `api-tokn`, a key the store doesn't have, so the operator set the object to `SyncError` and refused to materialize a partial Secret. The consumer, referencing a Secret that never existed, sat in `CreateContainerConfigError`. Correcting the `sourceKey` to `api-token` let the next reconcile resolve the key, materialize the Secret, and the kubelet started the waiting container on its own.

Two things worth keeping: a **derived Secret has its failure story in the object that produces it** — when a materialized Secret is missing or wrong, read the SecretSync/ExternalSecret `.status` before you touch the consumer, because that's where the failing step is named; and the operator **failed closed** — a broken reference produced *no* Secret, never a half-built one, which is exactly what you want from a secrets pipeline.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Sync-from-store: the External Secrets Operator.
- Continue to **`breakfix-02-store-access-denied`** — this time it isn't one reference; the operator can't read the store at all, and *every* sync is down.
