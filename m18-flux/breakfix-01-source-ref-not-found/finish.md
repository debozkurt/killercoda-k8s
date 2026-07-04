# Done

You diagnosed a pipeline that delivered nothing by reading it top-down: the `GitRepository` was `Ready: False` because it pointed at a branch (`release-2024`) the repo never had, so no artifact was produced and every consumer stalled waiting on it. Pointing the source at `main` and reconciling brought the whole pipeline back.

**Next:**

- For the canonical path and the patch-vs-fix-in-git discussion, see [ANSWER-KEY.md](../ANSWER-KEY.md).
- For the *why* — sources vs consumers and why a stalled source is invisible at the workload level — read [LESSON.md](../LESSON.md).
- **breakfix-02: Kustomization Suspended** — a hand-scaled Deployment won't revert and a change won't land, while `get` output looks healthy. The consumer is suspended.
