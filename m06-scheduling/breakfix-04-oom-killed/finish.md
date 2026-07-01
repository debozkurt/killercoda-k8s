# Done

The first three scenarios were the scheduler saying "no" — `Pending`, decided before the container ever started. This one was the kernel saying "no" *after* it started: `OOMKilled`, exit 137, on a loop. The Pod's memory **request** was small enough to schedule; its memory **limit** was smaller than the buffer it allocates, so it tripped the ceiling every launch. The fix raised the limit to fit the working set and touched nothing else.

That's the distinction the whole module turns on: **requests are what you fit; limits are what kill you.** A `Pending` Pod is a request/placement problem — read the `FailedScheduling` event. An `OOMKilled` / `CrashLoopBackOff` Pod that already has a node is a limit problem — read the Last State and exit 137. Same resource, opposite symptom, opposite fix.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The resource contract, and the deep dive on OOMKill vs. eviction vs. preemption.
- You've completed M06. Next module: **M07 — Workloads II (StatefulSets & DaemonSets)**, which builds on the identity and node-local placement you saw the fleet use here.
