# Done

The budget was sane. Allowed disruptions is current healthy minus desired healthy, and current healthy was 0: a readiness probe pointed at /healthz, which nginx answers with 404, so both replicas ran 0/1 Ready. Under the default `IfHealthyBudget` policy the eviction API refused even the unready Pods, because the budget had no healthy Pods to spare. Fixing the probe path made both Pods Ready and opened one disruption.

A zero in `ALLOWED DISRUPTIONS` has two sources: the floor you set and the health you have. Read `Current:`, `Desired:`, and `Total:` before you touch the budget. Loosening it hides the fault.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Disruption budgets.
- Next scenario: **`breakfix-05-sigterm-ignored`**. A Pod that will not leave.
