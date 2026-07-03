# Done

You diagnosed a value that was present in the release but sat at a key the chart never reads — `replicas` where the template wanted `replicaCount`. The tell was the gap between `helm get values` (what you asked for) and `helm get manifest` (what rendered). `helm get values -a` showed both keys side by side.

**Next:**

- For the canonical path and the `--set` vs values-in-git discussion, see [ANSWER-KEY.md](../ANSWER-KEY.md).
- For the *why* — values precedence and why Helm keeps unknown keys — read [LESSON.md](../LESSON.md).
- **breakfix-02: Bad Upgrade, Rollback** — an upgrade reports success but the new pods won't start. The revision history is the fix.
