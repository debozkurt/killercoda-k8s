# Done

You debugged a failure with no error: a healthy Pod simply missing a field a policy was supposed to inject. The tell was that `tenant-portal` ran fine — validation admitted it — so the break wasn't a rejection but an *absence*. Reading the `add-owner-label` policy's `match` against the Pod showed a one-character typo (`tenant-app` vs `tenant-apps`), so the mutate rule never selected the Pod. The fix was the **policy**, not the workload — the mirror image of breakfix-01.

The reflex to carry, and the reason this scenario exists: **a mutation happens only at admission.** Correcting the policy didn't relabel the running Pod; you had to `rollout restart` to push new Pods through the now-correct webhook. Whenever you fix a mutate policy, ask "does anything already running need re-admitting to pick up the change?" — the answer is almost always yes. (Kyverno's `mutateExisting` can patch live resources out-of-band, but that's a deliberate, separate mechanism, not the admission rewrite.)

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Mutation: rewriting at admission.
- Then **`breakfix-03-image-tag-rejected`** — the supply-chain gate: a Deployment blocked because its image is pinned to `:latest`.
