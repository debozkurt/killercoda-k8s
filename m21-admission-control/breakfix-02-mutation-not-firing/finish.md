# Done

You separated the *symptom* from the *fault*. The denial named the **validating** webhook and a missing `env` label — but the author never sets `env`; the **mutating** webhook injects it. Because the mutating webhook's `rules` matched `UPDATE` instead of `CREATE`, it never fired when the ReplicaSet *created* the Pod, so the label stayed absent and validation — which does match `CREATE` — rejected it. The fix was upstream, in the mutating configuration's `operations`; then a fresh admission (a `rollout restart`) let mutation run before validation, and the Pod carried `env=tenant`.

The reflexes to carry:

- **Order couples the two webhooks.** All mutating webhooks run, then all validating ones — so a validating rule can require what a mutating one injects. When a validating denial names a field the author never sets, suspect the mutating webhook that was supposed to supply it, and read *both* configurations.
- **A mutating webhook that doesn't match is silent.** No error, no event — it simply doesn't fire. The `rules` (`operations`, `resources`) and the selectors are exactly what decide whether it runs. A `CREATE`/`UPDATE` slip is a classic "the default that stopped being applied."
- **Mutation only happens at admission.** Fixing the configuration doesn't relabel anything already running; it takes effect on the next Pod that passes the webhook. Re-admit to apply it.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Ordering: mutate first, validate second.
- Then **`breakfix-03-webhook-scope-too-broad`** — a workload in `signaling` rejected by a webhook that only governs `tenant-apps`.
