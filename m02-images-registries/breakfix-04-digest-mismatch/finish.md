# Done

You closed out the differential. The status was `ImagePullBackOff` for the fourth time, but the event — `manifest unknown` — placed it on the bad-reference branch: reachable, authenticated, but pointing at a digest the registry never stored. You re-pinned to a digest that resolves (or fell back to the tag), keeping the fail-closed guarantee that a wrong digest never silently runs the wrong image.

You've now walked all four branches. The skill that ties them together isn't any single fix — it's reading the kubelet's event message *before* deciding what kind of failure you have:

```text
ErrImageNeverPull   → policy refused to pull        (breakfix-01)
no such host        → registry unreachable          (breakfix-02)
401 Unauthorized    → credentials rejected          (breakfix-03)
manifest unknown    → reference resolves to nothing (breakfix-04)
```

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) — including the promotion-by-digest production angle.
- For the full picture, read [`LESSON.md`](../LESSON.md).
- Next module: **M03 — Configuration** (ConfigMaps, Secrets, env injection) — how config, not just images, reaches your workloads.
