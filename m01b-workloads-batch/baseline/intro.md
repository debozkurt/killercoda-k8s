# M01b — Baseline Tour

M01 covered the workloads that *stay up* — Pods, Deployments, ReplicaSets. This module covers the other half of the family: workloads whose job is to **finish**.

A **Job** runs Pods until a set number of them exit successfully, then stops. A **CronJob** creates a Job on a schedule. Same controller machinery you already know, pointed at the opposite goal: not "keep N running" but "get N to complete."

This tour layers three batch workloads onto the healthy Polyphone fleet:

- **`schema-migrate`** (`provisioning`) — a one-shot Job: a run-to-completion schema migration
- **`usage-export`** (`analytics`) — a parallel Job: 4 daily shards, 2 at a time (`completions`/`parallelism`)
- **`cdr-rollup`** (`cdr-storage`) — a CronJob: rolls up Call Detail Records every minute (lab cadence)

Four short steps:

1. **The batch owner chains** — Job → Pod, and CronJob → Job → Pod
2. **Run-to-completion and restartPolicy** — why a Job exits where a Deployment never does
3. **completions and parallelism** — fixed-count and sharded work
4. **CronJob scheduling** — `schedule`, `LAST SCHEDULE`, history, and triggering a run by hand

Nothing to fix here. See what healthy batch looks like before the breakfix scenarios break it. The cluster takes 60–120 seconds to come up, and the CronJob needs up to a minute after that to fire its first Job. Click **Start** when ready.
