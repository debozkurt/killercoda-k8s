# Done

You caught a Job that was green and wrong: `Complete`, no errors, no retries — and silently processing one shard out of four. The tell wasn't in the status (which lied) or the logs (which were clean); it was the gap between `completions` and the real size of the work. You sized it correctly and recreated, because a Job's `completions` is immutable.

This is the hardest failure in the module precisely because it doesn't announce itself. `Complete` ≠ correct, the same way `Running` ≠ `Ready` in M01. The reflex worth keeping: when a batch job's *output* is questioned, check what it was told to do against what the work actually is — don't stop at the status column.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) — including `completionMode: Indexed`, which makes "which shard is missing?" answerable at a glance.
- For the *why*, see [`LESSON.md`](../LESSON.md) § completions and parallelism.
- You've finished M01b's break/fix set. Back to [`LESSON.md`](../LESSON.md) for the recap and production-thinking prompts.
