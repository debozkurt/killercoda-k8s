# Done

The `partner-api` Secret was missing because the pipeline never wrote it. The `SecretSync` named `api-tokn`, a key the store does not have. The operator set `SyncError` and wrote no Secret, so the consumer sat in `CreateContainerConfigError`. One patch to the reference fixed the sync, and the kubelet started the container on its next retry.

The instinct to keep: when a derived Secret is missing, read the producing object's status before you touch the consumer. A single failed sync points at its own reference.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § Sync-from-store for the three links that can break.
- Continue to `breakfix-02-store-access-denied`.
