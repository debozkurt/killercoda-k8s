# Done

`directory` was stuck `Pending` because it named a claim that didn't exist — `directory-store`, a typo for `directory-data`. A claim that isn't there can never bind, so the Pod waited on nothing. `describe pod` said it in words (`persistentvolumeclaim "..." not found`), and `get pvc` confirmed the named claim was absent — while `directory-data`, the claim it *should* have used, sat in the healthy `WaitForFirstConsumer` `Pending` because nothing was consuming it. The fix touched only the Pod's `claimName`; once a Pod finally referenced `directory-data`, it bound and started.

That's the second leaf: the claim the Pod *names* is `Pending` in break/fix 01 but *absent* here. The move that separates them is correlating the Pod's `claimName` (from `describe pod`) with the `get pvc` list — don't just scan which claims are `Pending`, check whether the one the Pod asks for is even there. Same first command, two different answers, two different fixes.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Binding, the get pvc triage, and what survives a delete.
- Next scenario: **`breakfix-03-rwo-multi-attach`** — this time the claim is `Bound`, and a Pod is *still* stuck.
