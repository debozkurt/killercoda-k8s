# Done

You read the fleet's placement from top to bottom. The control-plane taint keeps ordinary Pods on the worker, and only the `sbc-edge` toleration crosses it. Each fleet Pod carries requests below its limits, so each one is `Burstable`. A required node affinity pins `media-engine` to the node labeled `disktype=ssd`. The Pod you placed reserved its requests on the worker the moment the scheduler bound it, and released them when you deleted it.

That is the shape of healthy placement. Learn it, so each broken placement stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the five break/fix scenarios, in order. Four land on a branch of the `Pending` differential, and one flips to the runtime side:
  - **`breakfix-01-insufficient-resources`** — `Pending`, `Insufficient memory`: a request that fits no node.
  - **`breakfix-02-untolerated-taint`** — `Pending`, `untolerated taint`: a node that repels the Pod.
  - **`breakfix-03-antiaffinity-unschedulable`** — replicas `Pending`: a hard spread rule with nowhere to spread.
  - **`breakfix-04-oom-killed`** — the Pod schedules, then `OOMKilled`: a limit below the working set.
  - **`breakfix-05-node-affinity-mismatch`** — `Pending`, `didn't match Pod's node affinity/selector`: a label no node carries.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
