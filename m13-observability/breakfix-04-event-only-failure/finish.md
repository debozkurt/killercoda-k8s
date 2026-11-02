# Done

A workload had no logs because it never started. Its Pod waited in ContainerCreating, and the default namespace showed no events. The control plane recorded the cause as a Warning Event in another namespace: FailedMount, with the missing ConfigMap named in the message. Searching with `kubectl events -A --types=Warning` found it. Pointing the volume at the ConfigMap that exists let the container start.

The reflex: **a Pod that never started has no logs, only events.** Events are namespaced, so survey with `-A --types=Warning` when you do not know where to look. Then read the reason: it names the failing step. The event also expires after an hour, so read it early.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Events.
- Next scenario: **`breakfix-05-scrape-target-absent`**, flat dashboards with a correct port.
