# M01b — Break/fix 04: CronJob Stuck Under Forbid

> Pre-req: the M01b baseline tour, or comfort with `kubectl get cronjob/jobs`, the CronJob → Job → Pod chain, and `concurrencyPolicy`.

Same workload as break/fix 01, a different failure. The `cdr-rollup` CronJob in `cdr-storage` has gone stale again — billing reconciliation is drifting because no fresh rollups are landing. But this time it is **not suspended**, and there *is* a run: `kubectl get cronjob` shows `ACTIVE 1`.

So a run exists, yet the every-minute schedule has produced nothing new for a while. One run is in flight and the rest never start. That points straight at `concurrencyPolicy: Forbid` — the CronJob is allowed only one run at a time, and the one it has is going nowhere.

Your job is to find the stuck run, see why it's wedged the whole schedule, clear it, and add the guardrail that stops a single bad run from freezing the rollup again. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
