# Done

You diagnosed a change that applied cleanly and still did nothing. The ConfigMap held `debug`; the running container served `info`; nothing was in a failed state. The cause is propagation: **environment variables are frozen at container start, and a config edit restarts nothing on its own.** You made it take effect with `kubectl rollout restart` — and saw that the durable, GitOps-native version is a config-hash annotation that rolls consumers automatically.

This is configuration's instance of a theme that recurs across the curriculum: a green status that's still wrong. `Running` here didn't mean *running the current config* — just as M01's `Running` didn't mean `Ready` and M01b's `Complete` didn't mean correct. The next scenario is the sharpest version of it yet: a Pod that's `Running`, `Ready`, *and* serving a credential that's quietly garbage.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § "The update problem".
- Next scenario: **`breakfix-04-secret-double-base64`** — a Pod `Running` on a Secret that was encoded one time too many.
