# Done

A Deployment stuck `0/1` with **no Pods at all** — the signature of an *admission* rejection, not a scheduling or runtime one. The `payments` namespace enforces the `restricted` Pod Security Standard, and `payments-api` shipped with no `securityContext`, so every Pod its ReplicaSet tried to create was refused before it existed. The rejection lived where you had to go looking for it: a `FailedCreate` event on the ReplicaSet, quoting `violates PodSecurity "restricted:latest"` and listing each missing field. Setting them — `runAsNonRoot`, a non-root `runAsUser`, `allowPrivilegeEscalation: false`, `capabilities: drop [ALL]`, and a `seccompProfile` — let the Pod through.

The reflex: **a Deployment with zero Pods (not even `Pending`) is an admission problem — look at the ReplicaSet's events and the namespace's `pod-security…/enforce` label.** Fix the Pod to meet the standard; relaxing the namespace is a decision for the security team, not a debugging shortcut.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § securityContext and the Pod Security Standards.
- You've worked all three gates — authentication (identity), authorization (RBAC), and admission (PodSecurity). Re-open the baseline any time to re-read a healthy one.
