# M20 — Break/fix 02: A Mutation That Never Fired

> Pre-req: the M20 baseline tour. You've seen `add-owner-label` inject `owner=platform` onto a tenant Pod at admission; this is that injection silently *not* happening.

The cost-attribution report is complaining: a tenant workload, `tenant-portal`, shows up as "unowned." The platform convention is that every Pod in `tenant-apps` carries an `owner` label, injected automatically by a Kyverno `mutate` policy, and the reporting and on-call tooling group by it. `tenant-portal` is missing it.

Here's what makes this one different from the last: **`tenant-portal` is perfectly healthy.** It's `1/1`, its Pod is `Running`, nothing was rejected, nothing logs an error. Validation admitted it (it has limits and a pinned tag). The failure is an *absence* — a default that was supposed to be added, wasn't. Two things cause that: the mutate rule didn't `match` the Pod, or the Pod was admitted before the policy existed. Both look identical from the Pod.

Your job: confirm the label is missing, find the `add-owner-label` policy, and figure out why it didn't select `tenant-portal`'s Pods — then fix it and make the label actually land. That last part has a twist worth learning. The cluster plus Kyverno take about 2–4 minutes to come up. Click **Start** when ready.
