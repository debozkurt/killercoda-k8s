# Done

A Deployment at `0/1` with no Pods is the signature of an admission rejection. The `payments` namespace enforces `restricted`, and `payments-api` had no `securityContext`. `enforce` rejected each Pod the ReplicaSet tried to create. The refusal was a `FailedCreate` event on the ReplicaSet and a `ReplicaFailure` condition on the Deployment. It listed each missing field.

The reflex: **no Pods, not even `Pending`, means look upstream of the Pod**: the ReplicaSet's events and the namespace's labels. Fix the workload. A change to the namespace policy is a decision for the security owner, not a debugging step.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-05-rbac-wrong-apigroup`**. Back to RBAC, and the one field of the Forbidden sentence not yet broken.
