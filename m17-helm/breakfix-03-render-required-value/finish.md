# Done

You diagnosed a failed install with no cluster state to inspect — the failure was in the render step, before anything was applied. The render error named the missing value; `helm template` reproduced it offline; supplying `config.sipRealm` let the install through.

**Next:**

- For the canonical path and the `required`-vs-default design discussion, see [ANSWER-KEY.md](../ANSWER-KEY.md).
- For the *why* — the render pipeline, the `required` function, and `helm template` as your offline debugger — read [LESSON.md](../LESSON.md).
- **M17 is complete** (baseline + 3 break/fix). Next on the GitOps track: **M18 Flux** — GitRepository, Kustomization, HelmRelease, and drift.
