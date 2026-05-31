# M01b — Break/fix 04: Sidecar Blocks Job Completion

> Pre-req: the M01b baseline tour, plus the sidecar/multi-container Pod material from M01 (`LESSON.md` § why the Pod is the atom). You'll need the idea that a Pod is "done" only when *every* container exits.

A new batch job, `cdr-archive` in `cdr-storage`, copies each night's rolled-up Call Detail Records to cold storage. It ships with a `log-shipper` helper container that streams its logs to the platform's logging pipeline.

Since it was deployed, the archive **never finishes** — `kubectl get jobs` shows it stuck at `COMPLETIONS 0/1`, hour after hour. But here's the strange part: the archive *work itself* completes fine. The logs show the archive step finishing in seconds. Yet the Job never reports done, never triggers the downstream "archive complete" hook, and a duplicate fires the next night on top of it.

Nothing is crashing. Nothing is erroring. The work succeeds — and the Job still can't complete. Your job is to find why a successful batch run leaves its Job hanging forever, and fix it the modern way.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
