# Done

You read past a green `helm status` to a stuck rollout, found the bad image tag, and recovered with `helm rollback` to the last known-good revision — keeping Helm's release history and the live objects in sync.

**Next:**

- For the canonical path, the `rollout undo` drift trap, and the roll-forward-in-git alternative, see [ANSWER-KEY.md](../ANSWER-KEY.md).
- For the *why* — the release model, revisions, and `--wait`/`--atomic` — read [LESSON.md](../LESSON.md).
- **breakfix-03: Render Required Value** — an install fails outright and nothing deploys. Tests reading a render error and reproducing it offline.
