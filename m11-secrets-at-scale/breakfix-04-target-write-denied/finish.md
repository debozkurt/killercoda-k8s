# Done

The operator read the store and could not write the target. Its write grant for `provisioning` sat in `secrets-system`, next to the ServiceAccount. A RoleBinding grants only inside its own namespace, so the grant reached a namespace with no `SecretSync`. The operator reported `SecretWriteError` for `db-credentials` and kept syncing `partner-api`, which had a correct grant.

The instinct to keep: a failure confined to one namespace points at a per-namespace grant. Compare `auth can-i` for the controller across the healthy and the failing namespace.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § Sync-from-store, the table of three links.
- Continue to `breakfix-05-subpath-rotation-stale`.
