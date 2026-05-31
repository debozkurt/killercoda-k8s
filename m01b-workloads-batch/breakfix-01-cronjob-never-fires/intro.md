# M01b — Break/fix 01: CronJob Never Fires

> Pre-req: the M01b baseline tour, or comfort with `kubectl get cronjob/jobs` and the CronJob → Job → Pod chain.

A data engineer pings you: **the Call Detail Record rollup hasn't produced output in a while.** Billing reconciliation is drifting because the aggregated CDRs downstream are stale.

`cdr-rollup` in `cdr-storage` is a CronJob — it's supposed to fire on a schedule and roll up records. But there are no recent rollup Jobs, no pods, no error logs, no events screaming at you. Nothing is *crashing*. It's just… not happening.

This is the quiet batch failure: a scheduled task that stopped, with no alert and no obvious symptom. Your job is to work the CronJob differential — the short list of reasons a CronJob creates nothing — find which one applies, and get it firing again.

The fix is one field. The skill is knowing the differential cold, so a silent CronJob takes you two minutes, not twenty. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
