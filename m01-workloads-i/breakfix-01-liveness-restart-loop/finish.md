# Done

You diagnosed a `CrashLoopBackOff` that wasn't a crash. The tell was the sequence: clean `logs --previous`, then `Liveness probe failed` + `Killing` in `describe` — a healthy container killed on a timer by a probe pointed at a path it never served. The fix was one field, but only after you proved *what* was doing the killing.

That distinction — real crash versus liveness killing a good process — is the whole lesson. Reach for the wrong one and you spend an incident debugging code that was never broken.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) — including the rule of thumb for when a workload should have a liveness probe at all.
- For the *why*, see [`LESSON.md`](../LESSON.md) § the three probes.
- Next scenario: **`breakfix-02-readiness-traffic-blackhole`** — the gentler sibling. A failing readiness probe doesn't restart anything; it quietly pulls every replica out of rotation.
