# Done

Admission accepted `ledger-sync`, because its spec met every `restricted` rule. The kubelet refused the container, because `runAsNonRoot: true` met an image that runs as root. The Pod existed, its status read `CreateContainerConfigError`, and a kubelet event named the reason. A non-root `runAsUser` fixed it.

Compare it with break/fix 04:

- No Pod at all: admission rejected it. Read the ReplicaSet.
- A Pod that never starts its container: the kubelet refused it. Read the Pod.

`runAsNonRoot` checks the user and never sets it.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- That is the last M10 scenario. Re-read the LESSON's Common failure modes table to consolidate the differential.
