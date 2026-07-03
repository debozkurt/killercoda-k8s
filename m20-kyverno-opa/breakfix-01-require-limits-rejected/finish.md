# Done

You read a `0/N`-with-no-Pods for what it is: not a scheduling or image failure, but an **admission** rejection of the Pods a ReplicaSet keeps trying to create. The reason lived on the ReplicaSet's `FailedCreate` event, and the `admission webhook "validate.kyverno.svc-fail" denied the request` line named the policy (`require-resource-limits`), the rule, and the reason — every field you needed to find the cause. The workload declared `requests` but no `limits`, which the Enforce policy rejects. The fix was the *workload* — add the limits — because the policy was doing exactly its job.

The reflex to carry: **`admission webhook denied` is a policy event, not a workload bug.** Read the message for the policy and rule, read that rule against your object, then decide whether the object should comply (usually) or the policy is wrong (sometimes). And the shape of *where* it lands is Kyverno's autogen setting: this policy has autogen off, so the denial surfaced on the ReplicaSet; with autogen on — the default — the very same violation is rejected at `kubectl apply` instead.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Validation: rejecting the non-compliant.
- Then **`breakfix-02-mutation-not-applied`** — a workload that runs, but is quietly missing a field a policy was supposed to inject.
