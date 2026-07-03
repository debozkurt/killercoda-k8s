# M11 — Break/fix 01: SecretSync SyncError (Missing Source Key)

> The healthy pipeline from the baseline, with one broken reference. Work the store → sync → Secret → consumer chain backward.

The `partner-connector` workload in the `media` namespace won't start. Its Pod sits in `CreateContainerConfigError`, and the `partner-api` Secret it depends on isn't there. Meanwhile the other half of the pipeline — `billing-processor` and its `db-credentials` Secret — is completely fine.

The reflex from M03 is to go straight at the Pod: check its env references, look for a missing Secret. That gets you halfway — the Secret *is* missing — but not to *why*. This Secret isn't hand-written; it's **materialized** by the operator from a SecretSync. So the question isn't "who deleted the Secret," it's "why did the pipeline never produce it." And a controller answers that question in one place: the object's `.status`.

Your job: read the SecretSync's status to find the failing step, confirm it against the store, and correct the reference so the Secret materializes and the consumer starts. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
