# M11 — Break/fix 03: Rotation Not Propagated (Stale Consumer)

> Pre-req: breakfix-01 and 02. Both had a broken link you could see in `.status`. This one has no broken link at all — the pipeline is green end to end, and a consumer is still wrong.

Overnight, the database password was rotated in the store. The secrets pipeline did its job: the operator synced the new value, every SecretSync reads `Synced`, and the `db-credentials` Secret holds the new password. By every status you'd normally check, this is healthy.

But `billing-processor` is failing its database connections, because it's still presenting the *old* password. Nothing is red. `kubectl get secretsync`, `kubectl get secret`, the operator's logs — all green. This is the failure mode the pipeline's status can't show you, because the pipeline isn't where it lives.

The instinct that's been building since M01 is the one you need here: a green headline status doesn't mean the system is right. `Running` ≠ `Ready`, `Complete` ≠ correct, and now `Synced` ≠ *the consumer is using it*. Your job: find where the old value is still alive by reading what the process actually holds, explain why the rotation stopped short of it, and make it land. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
