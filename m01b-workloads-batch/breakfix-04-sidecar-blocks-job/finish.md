# Done

You diagnosed a Job that couldn't complete even though its work succeeded. The contradiction pointed straight at the cause: a Pod is `Succeeded` only when *every* container terminates, and an ordinary `log-shipper` sidecar running `tail -f` never does — so it pinned the Pod (and the Job) in `Running` forever. The fix wasn't to delete the helper; it was to make it a **native sidecar** (an `initContainer` with `restartPolicy: Always`) so the kubelet stops it once the archive container exits.

This is one of the most common real-world batch failures — most often a service-mesh proxy injected as an ordinary sidecar, silently keeping every Job Pod alive. It's also where M01's "the Pod is the atom" idea pays off: the same multi-container lifecycle that makes sidecars useful is what makes a misplaced one block completion.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) — including the full multi-container completion rule and the native-sidecar shutdown ordering.
- For the *why*, see [`LESSON.md`](../LESSON.md) § the Job, and M01 `LESSON.md` § why the Pod is the atom (native sidecars).
- You've finished M01b's break/fix set (four scenarios). Back to [`LESSON.md`](../LESSON.md) for the recap and production-thinking prompts.
