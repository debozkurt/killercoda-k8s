# Done

The workload was healthy and the budget was the block. `ALLOWED DISRUPTIONS` read 0 because the floor (2) equaled the replica count (2): current healthy minus desired healthy is 0. The eviction API refused every eviction, and a drain retries a refusal without end. Lowering the floor to 1 opened one disruption.

The fix only removed the budget as the blocker. A drain also needs room for each replacement to become Ready elsewhere. On this cluster, with the worker cordoned, the replacement stayed `Pending` and allowed disruptions fell back to 0.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Disruption budgets.
- Next scenario: **`breakfix-02-hpa-no-requests`**. An autoscaler that cannot read its own metric.
