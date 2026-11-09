# Done

The release record is also a lock. Helm wrote revision 2 as `pending-upgrade` before it applied, and the cancelled job never moved it on. Every later upgrade saw a pending latest revision and refused. `helm rollback` wrote revision 3 as `deployed`, which cleared the lock and restored the healthy memory request. The greeting upgrade then ran as revision 4.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) covers how to prevent a stale lock and how to detect one.
- [LESSON.md](../LESSON.md) covers the release record and `--rollback-on-failure`.
- **M17 is complete.** Next on the GitOps track: **M18 Flux**, where a controller runs the same Helm operations from git.
