# Done

The first three scenarios were the scheduler saying no: the Pods stayed `Pending`, and no container ever started. This one was the kernel saying no after the start: `OOMKilled`, exit code 137, in a loop. The memory request was small enough to schedule. The memory limit was smaller than the buffer the container allocates, so each start went over it. The fix raised the limit to fit the working set and changed nothing else.

The whole module turns on this distinction: **requests are what you fit, and limits are what kill you.** A `Pending` Pod is a placement problem, so read the `FailedScheduling` event. A Pod that has a node and loops with `OOMKilled` is a limit problem, so read `Last State:`.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The resource contract, and the deep dive on OOMKill, eviction and preemption.
- Next scenario: **`breakfix-05-node-affinity-mismatch`**. Back to `Pending`, on the one filter branch the other scenarios did not reach.
