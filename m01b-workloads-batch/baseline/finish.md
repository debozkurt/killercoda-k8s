# Done

You toured the batch half of the workload family on healthy workloads: the Job → Pod and CronJob → Job → Pod owner chains, a Job running to completion under `restartPolicy: OnFailure`, a parallel Job sized by `completions`/`parallelism`, and a CronJob firing on schedule with bounded history. That's the shape of "healthy" batch — internalize it so "broken" stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each breaks a different link in the chain:
  - **`breakfix-01-cronjob-never-fires`** — a scheduled rollup that quietly stopped. The CronJob differential.
  - **`breakfix-02-job-backofflimit`** — a Job whose Pods keep failing; retrying, then `Failed`.
  - **`breakfix-03-completions-shortfall`** — a Job that reports `Complete` but only did part of the work.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
