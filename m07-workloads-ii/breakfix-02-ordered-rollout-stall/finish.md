# Done

`READY 0/3` with only one Pod present looked like most of the set had failed to deploy — but nothing failed to deploy. `session-store-0` was Running with a readiness probe aimed at port 8080 while the container served on 80, so it never went Ready; and under the default `OrderedReady` policy the controller refuses to create ordinal `N+1` until ordinal `N` is Ready. One un-ready Pod-0 was the whole reason `-1` and `-2` didn't exist. Correcting the probe's port let Pod-0 pass, and the ordered rollout completed on its own.

Two things worth keeping: **in a StatefulSet, one Pod's un-readiness stalls the entire rollout** — a Deployment would have created all three and let the healthy ones serve; and **the missing Pods were a symptom, not the bug** — the fix was always at ordinal 0. (If your app genuinely doesn't need ordered startup, `podManagementPolicy: Parallel` removes this gate while keeping stable names and storage.)

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Ordered lifecycle.
- Next scenario: **`breakfix-03-daemonset-node-coverage`** — from StatefulSets to the other controller: a node-local agent that quietly runs on fewer nodes than you have.
