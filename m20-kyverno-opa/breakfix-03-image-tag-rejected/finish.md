# Done

You worked the image-admission gate. The top-line looked identical to breakfix-01 — a Deployment at `0/1` with no Pods, an admission rejection on the ReplicaSet — but the denial named a *different* policy, `disallow-latest-tag`, and the fix was different in kind: not a missing field, but a mutable `:latest` tag the supply-chain policy refuses. Pinning the image to `nginx:1.25` made the object comply, and the same policy that rejected `:latest` admitted the pinned tag.

The reflex to carry: **read *which* policy the denial names.** Two workloads can fail with the same `0/N` shape for entirely different reasons — a limits rule vs an image rule — and the policy name in the `admission webhook denied` message tells them apart before you touch anything. And image admission is a spectrum: forbidding `:latest` is the cheapest rung; allow-listing registries and verifying cosign signatures (`verifyImages`) are the stronger ones, all answering the same question — *what is allowed to run here* — at the one gate where you can still say no before the image is pulled.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Image admission: what is allowed to run here.
- You've worked all three scenarios: a validation rejection (fix the workload), a mutation gap (fix the policy, then re-admit), and an image rejection (pin the tag). Together they are the three rule types a policy engine enforces at admission.
